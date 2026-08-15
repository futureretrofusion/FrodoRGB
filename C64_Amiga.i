/* Modified 2026-06-21 by Future Retro Fusion for FRF 2026 Frodo RTG. */
#include "FRFBuildConfig.h"
#include "FrodoFRFTrace.h"

/*
#include <proto/graphics.h>
#include <proto/dos.h>
 *  C64_Amiga.i - Put the pieces together, Amiga specific stuff
 *
 *  Frodo (C) 1994-1997,2002 Christian Bauer
 */

#include <proto/exec.h>
#include <proto/timer.h>


// Library bases
struct Device *TimerBase;

extern char FrodoStartupSnapshotPath[256];
extern int FrodoFRFMaybeInjectStartupPRG(C64 *c64);

/*
 *  Constructor, system-dependent things
 */

void C64::c64_ctor1(void)
{
	// Open game_io
	FrodoFRFTrace("C64_AMIGA before game_port CreateMsgPort");
        game_port = CreateMsgPort();
        FrodoFRFTrace("C64_AMIGA after game_port CreateMsgPort");
	game_io = (struct IOStdReq *)CreateIORequest(game_port, sizeof(IOStdReq));
	game_io->io_Message.mn_Node.ln_Type = NT_UNKNOWN;
	game_open = port_allocated = false;
	if (!OpenDevice("gameport.device", 1, (struct IORequest *)game_io, 0))
		game_open = true;
}

void C64::c64_ctor2(void)
{
	// Initialize joystick variables
	joy_state = 0xff;

	// Open timer_io
	FrodoFRFTrace("C64_AMIGA before timer_port CreateMsgPort");
        timer_port = CreateMsgPort();
        FrodoFRFTrace("C64_AMIGA after timer_port CreateMsgPort");
	timer_io = (struct timerequest *)CreateIORequest(timer_port, sizeof(struct timerequest));
	OpenDevice(TIMERNAME, UNIT_MICROHZ, (struct IORequest *)timer_io, 0);

	// Get timer base
	TimerBase = timer_io->tr_node.io_Device;

	// Preset speedometer start time
	GetSysTime(&start_time);
}


/*
 *  Destructor, system-dependent things
 */

void C64::c64_dtor(void)
{
	// Stop and delete timer_io
	if (timer_io != NULL) {
		if (!CheckIO((struct IORequest *)timer_io))
			WaitIO((struct IORequest *)timer_io);
		CloseDevice((struct IORequest *)timer_io);
		DeleteIORequest((struct IORequest *)timer_io);
	}

	if (timer_port != NULL)
		DeleteMsgPort(timer_port);

	if (game_open) {
		if (!CheckIO((struct IORequest *)game_io)) {
			AbortIO((struct IORequest *)game_io);
			WaitIO((struct IORequest *)game_io);
		}
		CloseDevice((struct IORequest *)game_io);
	}

	if (game_io != NULL)
		DeleteIORequest((struct IORequest *)game_io);

	if (game_port != NULL)
		DeleteMsgPort(game_port);
}


/*
 *  Start emulation
 */

void C64::Run(void)
{
        FrodoFRFTrace("C64_AMIGA Run enter");
	// Reset chips
	TheCPU->Reset();
	TheSID->Reset();
	TheCIA1->Reset();
	TheCIA2->Reset();
	TheCPU1541->Reset();

	// Patch kernal IEC routines
	orig_kernal_1d84 = Kernal[0x1d84];
	orig_kernal_1d85 = Kernal[0x1d85];
	PatchKernal(ThePrefs.FastReset, ThePrefs.Emul1541Proc);

	// Start timer_io
	timer_io->tr_node.io_Command = TR_ADDREQUEST;
	timer_io->tr_time.tv_secs = 0;
	timer_io->tr_time.tv_micro = ThePrefs.SkipFrames * 20000;  // 20ms per frame
	SendIO((struct IORequest *)timer_io);

	// Start the CPU thread
	thread_running = true;
	quit_thyself = false;
	have_a_break = false;
	thread_func();
}


/*
 *  Stop emulation
 */

void C64::Quit(void)
{
	// Ask the thread to quit itself if it is running
	if (thread_running) {
		quit_thyself = true;
		thread_running = false;
	}
}


/*
 *  Pause emulation
 */

void C64::Pause(void)
{
        have_a_break = true;
        TheSID->PauseSound();
}


/*
 *  Resume emulation
 */

void C64::Resume(void)
{
        have_a_break = false;
        TheSID->ResumeSound();
}


/*
 *  Vertical blank: Poll keyboard and joysticks, update window
 */

void C64::VBlank(bool draw_frame)
{
        /*
         * FRF 2026: delayed startup snapshot load at first VBlank.
         *
         * C64::LoadSnapshot() wants the emulator paused and in VBlank.
         * Loading before C64::Run() is too early and can be wiped by Run().
         */
        if (FrodoStartupSnapshotPath[0]) {
                char frf_snapshot_path[256];

                strncpy(frf_snapshot_path, FrodoStartupSnapshotPath, sizeof(frf_snapshot_path) - 1);
                frf_snapshot_path[sizeof(frf_snapshot_path) - 1] = 0;
                FrodoStartupSnapshotPath[0] = 0;

                have_a_break = true;
                TheSID->PauseSound();
                LoadSnapshot(frf_snapshot_path);
                have_a_break = false;
                TheSID->ResumeSound();
        }


	struct timeval end_time;
	long speed_index;

	// Poll keyboard
	TheDisplay->PollKeyboard(TheCIA1->KeyMatrix, TheCIA1->RevMatrix, &joykey);

	// Poll joysticks
	TheCIA1->Joystick1 = poll_joystick(0);
	TheCIA1->Joystick2 = poll_joystick(1);

	if (ThePrefs.JoystickSwap) {
		uint8 tmp = TheCIA1->Joystick1;
		TheCIA1->Joystick1 = TheCIA1->Joystick2;
		TheCIA1->Joystick2 = tmp;
	}

	// Joystick keyboard emulation
	if (TheDisplay->NumLock())
		TheCIA1->Joystick1 &= joykey;
	else
		TheCIA1->Joystick2 &= joykey;

	// Count TOD clocks
	TheCIA1->CountTOD();
	TheCIA2->CountTOD();

	// Update window if needed
	if (draw_frame) {
    	TheDisplay->Update();

		// Calculate time between VBlanks, display speedometer
		GetSysTime(&end_time);
		SubTime(&end_time, &start_time);
		speed_index = 20000 * 100 * ThePrefs.SkipFrames / (end_time.tv_micro + 1);

		// Abort timer_io if speed limiter is off
		if (!ThePrefs.LimitSpeed) {
			if (!CheckIO((struct IORequest *)timer_io))
				AbortIO((struct IORequest *)timer_io);
		} else if (speed_index > 100)
			speed_index = 100;

		// Wait for timer_io (limit speed)
		WaitIO((struct IORequest *)timer_io);

		// Restart timer_io
		timer_io->tr_node.io_Command = TR_ADDREQUEST;
		timer_io->tr_time.tv_secs = 0;
		timer_io->tr_time.tv_micro = ThePrefs.SkipFrames * 20000;  // 20ms per frame
		SendIO((struct IORequest *)timer_io);

		GetSysTime(&start_time);

		TheDisplay->Speedometer(speed_index);
	}
}


/*
 *  Open/close joystick drivers given old and new state of
 *  joystick preferences
 */

void C64::open_close_joysticks(bool oldjoy1, bool oldjoy2, bool newjoy1, bool newjoy2)
{
	if (game_open && (oldjoy2 != newjoy2))

		if (newjoy2) {	// Open joystick
			joy_state = 0xff;
			port_allocated = false;

			// Allocate game port
			BYTE ctype;
			Forbid();
			game_io->io_Command = GPD_ASKCTYPE;
			game_io->io_Data = &ctype;
			game_io->io_Length = 1;
			DoIO((struct IORequest *)game_io);

			if (ctype != GPCT_NOCONTROLLER)
				Permit();
			else {
				ctype = GPCT_ABSJOYSTICK;
				game_io->io_Command = GPD_SETCTYPE;
				game_io->io_Data = &ctype;
				game_io->io_Length = 1;
				DoIO((struct IORequest *)game_io);
				Permit();

				port_allocated = true;

				// Set trigger conditions
				game_trigger.gpt_Keys = GPTF_UPKEYS | GPTF_DOWNKEYS;
				game_trigger.gpt_Timeout = 65535;
				game_trigger.gpt_XDelta = 1;
				game_trigger.gpt_YDelta = 1;
				game_io->io_Command = GPD_SETTRIGGER;
				game_io->io_Data = &game_trigger;
				game_io->io_Length = sizeof(struct GamePortTrigger);
				DoIO((struct IORequest *)game_io);

				// Flush device buffer
				game_io->io_Command = CMD_CLEAR;
				DoIO((struct IORequest *)game_io);

				// Start reading joystick events
				game_io->io_Command = GPD_READEVENT;
				game_io->io_Data = &game_event;
				game_io->io_Length = sizeof(struct InputEvent);
				SendIO((struct IORequest *)game_io);
			}

		} else {	// Close joystick

			// Abort game_io
			if (!CheckIO((struct IORequest *)game_io)) {
				AbortIO((struct IORequest *)game_io);
				WaitIO((struct IORequest *)game_io);
			}

			// Free game port
			if (port_allocated) {
				BYTE ctype = GPCT_NOCONTROLLER;
				game_io->io_Command = GPD_SETCTYPE;
				game_io->io_Data = &ctype;
				game_io->io_Length = 1;
				DoIO((struct IORequest *)game_io);

				port_allocated = false;
			}
		}
}


/*
 *  Poll joystick port, return CIA mask
 */

uint8 C64::poll_joystick(int port)
{
	if (port == 0)
		return 0xff;

	if (game_open && port_allocated) {

		// Joystick event arrived?
		while (GetMsg(game_port) != NULL) {

			// Yes, analyze event
			switch (game_event.ie_Code) {
				case IECODE_LBUTTON:					// Button pressed
					joy_state &= 0xef;
					break;

				case IECODE_LBUTTON | IECODE_UP_PREFIX:	// Button released
					joy_state |= 0x10;
					break;

				case IECODE_NOBUTTON:					// Joystick moved
					if (game_event.ie_X == 1)
						joy_state &= 0xf7;				// Right
					if (game_event.ie_X == -1)
						joy_state &= 0xfb;				// Left
					if (game_event.ie_X == 0)
						joy_state |= 0x0c;
					if (game_event.ie_Y == 1)
						joy_state &= 0xfd;				// Down
					if (game_event.ie_Y == -1)
						joy_state &= 0xfe;				// Up
					if (game_event.ie_Y == 0)
						joy_state |= 0x03;
					break;
			}

			// Start reading the next event
			game_io->io_Command = GPD_READEVENT;
			game_io->io_Data = &game_event;
			game_io->io_Length = sizeof(struct InputEvent);
			SendIO((struct IORequest *)game_io);
		}
		return joy_state;

	} else
		return 0xff;
}


/*
 * The emulation's main loop
 */

void C64::thread_func(void)
{
        FrodoFRFTrace("C64_AMIGA thread_func enter");
	while (!quit_thyself) {

                /*
                 * FRF 2026: real emulation pause.
                 *
                 * Old Amiga Pause() only stopped SID audio.
                 * This keeps the Intuition/rawkey path alive so Ctrl-P
                 * can resume without advancing CPU/VIC/CIA/SID emulation.
                 */
                if (have_a_break) {
                        TheDisplay->PollKeyboard(TheCIA1->KeyMatrix, TheCIA1->RevMatrix, &joykey);
                        Delay(1);
                        continue;
                }

                /* Restored FRF PRG DIR51B drive-8 startup loader. */
                FrodoFRFMaybeInjectStartupPRG(this);

#ifdef FRODO_SC
		// The order of calls is important here
		if (TheVIC->EmulateCycle())
			TheSID->EmulateLine();
		TheCIA1->CheckIRQs();
		TheCIA2->CheckIRQs();
		TheCIA1->EmulateCycle();
		TheCIA2->EmulateCycle();
		TheCPU->EmulateCycle();

		if (ThePrefs.Emul1541Proc) {
			TheCPU1541->CountVIATimers(1);
			if (!TheCPU1541->Idle)
				TheCPU1541->EmulateCycle();
		}
		CycleCounter++;
#else
		// The order of calls is important here
		int cycles = TheVIC->EmulateLine();
		TheSID->EmulateLine();
#if !PRECISE_CIA_CYCLES
		TheCIA1->EmulateLine(ThePrefs.CIACycles);
		TheCIA2->EmulateLine(ThePrefs.CIACycles);
#endif

		if (ThePrefs.Emul1541Proc) {
			int cycles_1541 = ThePrefs.FloppyCycles;
			TheCPU1541->CountVIATimers(cycles_1541);

			if (!TheCPU1541->Idle) {
				// 1541 processor active, alternately execute
				//  6502 and 6510 instructions until both have
				//  used up their cycles
				while (cycles >= 0 || cycles_1541 >= 0)
					if (cycles > cycles_1541)
						cycles -= TheCPU->EmulateLine(1);
					else
						cycles_1541 -= TheCPU1541->EmulateLine(1);
			} else
				TheCPU->EmulateLine(cycles);
		} else
			// 1541 processor disabled, only emulate 6510
			TheCPU->EmulateLine(cycles);
#endif
	}
}
