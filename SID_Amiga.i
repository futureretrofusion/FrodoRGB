/* Modified 2026-06-21 by Future Retro Fusion for FRF 2026 Frodo RTG. */
#include "FRFBuildConfig.h"
#include "FrodoFRFTrace.h"

/*
 *  SID_Amiga.i - 6581 emulation, Amiga specific stuff
 *
 *  Frodo (C) 1994-1997,2002 Christian Bauer
 */

#include <dos/dostags.h>
#include <hardware/cia.h>
#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/ahi.h>
#include <proto/graphics.h>


// Library bases
struct Library *AHIBase;

// CIA-A base
extern struct CIA ciaa;


/*
 *  Initialization, create sub-process
 */

void DigitalRenderer::init_sound(void)
{
        main_task = FindTask(NULL);
        ready = FALSE;
        sound_process = NULL;
        quit_sig = pause_sig = resume_sig = ahi_sig = -1;
        init_sig = main_sig = -1;

        /*
         * FRF 2026:
         * Wait only until the sound task has allocated its command signals.
         * AHI device setup remains asynchronous, so another Frodo instance
         * cannot hold C64 construction on a grey screen.
         *
         * Startup and shutdown use different main-task signals. This avoids
         * a stale startup/ready signal being mistaken for "task exited".
         */
        init_sig = AllocSignal(-1);
        main_sig = AllocSignal(-1);
        if (init_sig < 0 || main_sig < 0) {
                if (init_sig >= 0)
                        FreeSignal(init_sig);
                if (main_sig >= 0)
                        FreeSignal(main_sig);
                init_sig = main_sig = -1;
                return;
        }

        sound_process = CreateNewProcTags(
                NP_Entry, (ULONG)&sub_invoc,
                NP_Name, (ULONG)"FRF Frodo Sound Process",
                NP_Priority, 1,
                NP_ExitData, (ULONG)this,
                TAG_DONE);

        if (sound_process == NULL) {
                FreeSignal(init_sig);
                FreeSignal(main_sig);
                init_sig = main_sig = -1;
                return;
        }

        Wait(1UL << init_sig);

        /* A command-signal allocation failure makes the child exit cleanly. */
        if (quit_sig < 0 || pause_sig < 0 || resume_sig < 0 || ahi_sig < 0) {
                Wait(1UL << main_sig);
                sound_process = NULL;
        }
}



/*
 *  Destructor, delete sub-process
 */

DigitalRenderer::~DigitalRenderer()
{
        ready = FALSE;

	// Tell sub-process to quit and wait for actual completion.
	if (sound_process != NULL && quit_sig >= 0 && main_sig >= 0) {
		Signal(&(sound_process->pr_Task), 1UL << quit_sig);
		Wait(1UL << main_sig);
                sound_process = NULL;
	}

        if (init_sig >= 0)
                FreeSignal(init_sig);
        if (main_sig >= 0)
                FreeSignal(main_sig);
        init_sig = main_sig = -1;
}


/*
 *  Sample volume (for sampled voice)
 */

void DigitalRenderer::EmulateLine(void)
{
	sample_buf[sample_in_ptr] = volume;
	sample_in_ptr = (sample_in_ptr + 1) % SAMPLE_BUF_SIZE;
}


/*
 *  Pause sound output
 */

void DigitalRenderer::Pause(void)
{
     if (sound_process != NULL && pause_sig >= 0)
             Signal(&(sound_process->pr_Task), 1UL << pause_sig);
}




/*
 *  Resume sound output
 */

void DigitalRenderer::Resume(void)
{
    if (sound_process != NULL && resume_sig >= 0)
            Signal(&(sound_process->pr_Task), 1UL << resume_sig);
}




/*
 *  Sound sub-process
 */

void DigitalRenderer::sub_invoc(void)
{
	// Get pointer to the DigitalRenderer object and call sub_func()
	DigitalRenderer *r = (DigitalRenderer *)((struct Process *)FindTask(NULL))->pr_ExitData;
	r->sub_func();
}


void DigitalRenderer::sub_func(void)
{
    BOOL device_open = FALSE;
    ULONG sigs = 0;

    FrodoFRFTrace("SID sub_func enter");

    ahi_port = NULL;
    ahi_io = NULL;
    ahi_ctrl = NULL;
    sample[0].ahisi_Address = sample[1].ahisi_Address = NULL;
    ready = FALSE;

    // Create signals for communication
    quit_sig = AllocSignal(-1);
    pause_sig = AllocSignal(-1);
    resume_sig = AllocSignal(-1);
    ahi_sig = AllocSignal(-1);

    // Tell init_sound() that command signals are now stable.
    Signal(main_task, 1UL << init_sig);
    if (quit_sig < 0 || pause_sig < 0 || resume_sig < 0 || ahi_sig < 0)
            goto quit;

    // Initialize callback hook once
    sf_hook.h_Entry = sound_func;

retry_audio:
    /*
     * FRF 2026:
     * Try to claim AHI. If another Frodo instance owns it, do not die
     * forever. Enter silent wait mode until this instance is resumed/focused.
     */
    FrodoFRFTrace("SID retry_audio begin");

    ready = FALSE;
    device_open = FALSE;
    AHIBase = NULL;

    ahi_port = CreateMsgPort();
    if (ahi_port == NULL) {
        FrodoFRFTrace("SID retry_audio: CreateMsgPort failed");
        goto audio_failed;
    }

    ahi_io = (struct AHIRequest *)CreateIORequest(ahi_port, sizeof(struct AHIRequest));
    if (ahi_io == NULL) {
        FrodoFRFTrace("SID retry_audio: CreateIORequest failed");
        goto audio_failed;
    }

    ahi_io->ahir_Version = 2;

    FrodoFRFTrace("SID retry_audio: before OpenDevice");
    if (OpenDevice(AHINAME, AHI_NO_UNIT, (struct IORequest *)ahi_io, NULL)) {
        FrodoFRFTrace("SID retry_audio: OpenDevice failed");
        goto audio_failed;
    }

    device_open = TRUE;
    FrodoFRFTrace("SID retry_audio: after OpenDevice");

    AHIBase = (struct Library *)ahi_io->ahir_Std.io_Device;

    FrodoFRFTrace("SID retry_audio: before AHI_AllocAudio");
    ahi_ctrl = AHI_AllocAudio(
            AHIA_AudioID, 0x0002000b,
            AHIA_MixFreq, SAMPLE_FREQ,
            AHIA_Channels, 1,
            AHIA_Sounds, 2,
            AHIA_SoundFunc, (ULONG)&sf_hook,
            AHIA_UserData, (ULONG)this,
            TAG_DONE);

    if (ahi_ctrl == NULL) {
        FrodoFRFTrace("SID retry_audio: AHI_AllocAudio failed");
        goto audio_failed;
    }

    FrodoFRFTrace("SID retry_audio: after AHI_AllocAudio");

    // Prepare SampleInfos and load sounds (two sounds for double buffering)
    sample[0].ahisi_Type = AHIST_M16S;
    sample[0].ahisi_Length = SAMPLE_FREQ / CALC_FREQ;
    sample[1].ahisi_Type = AHIST_M16S;
    sample[1].ahisi_Length = SAMPLE_FREQ / CALC_FREQ;

    if (sample[0].ahisi_Address == NULL)
        sample[0].ahisi_Address = AllocVec(SAMPLE_FREQ / CALC_FREQ * 2, MEMF_PUBLIC | MEMF_CLEAR);
    if (sample[1].ahisi_Address == NULL)
        sample[1].ahisi_Address = AllocVec(SAMPLE_FREQ / CALC_FREQ * 2, MEMF_PUBLIC | MEMF_CLEAR);

    if (sample[0].ahisi_Address == NULL || sample[1].ahisi_Address == NULL) {
        FrodoFRFTrace("SID retry_audio: sample AllocVec failed");
        goto audio_failed;
    }

    AHI_LoadSound(0, AHIST_DYNAMICSAMPLE, &sample[0], ahi_ctrl);
    AHI_LoadSound(1, AHIST_DYNAMICSAMPLE, &sample[1], ahi_ctrl);

    // Set parameters
    play_buf = 0;
    AHI_SetVol(0, 0x10000, 0x8000, ahi_ctrl, AHISF_IMM);
    AHI_SetFreq(0, SAMPLE_FREQ, ahi_ctrl, AHISF_IMM);
    AHI_SetSound(0, play_buf, 0, 0, ahi_ctrl, AHISF_IMM);

    // Start audio output
    AHI_ControlAudio(ahi_ctrl, AHIC_Play, TRUE, TAG_DONE);

    ready = TRUE;
    FrodoFRFTrace("SID retry_audio: ready");

    // Accept and execute commands
    for (;;) {
        sigs = Wait((1UL << quit_sig) | (1UL << pause_sig) | (1UL << resume_sig) | (1UL << ahi_sig));

        // Quit sub-process
        if (sigs & (1UL << quit_sig))
            goto quit;

        // Pause sound output and fully release AHI
        if (sigs & (1UL << pause_sig)) {
            FrodoFRFTrace("SID pause: release AHI");

            if (ahi_ctrl != NULL) {
                AHI_ControlAudio(ahi_ctrl, AHIC_Play, FALSE, TAG_DONE);
                AHI_FreeAudio(ahi_ctrl);
                ahi_ctrl = NULL;
            }

            if (device_open && ahi_io != NULL) {
                CloseDevice((struct IORequest *)ahi_io);
                device_open = FALSE;
            }

            if (ahi_io != NULL) {
                DeleteIORequest((struct IORequest *)ahi_io);
                ahi_io = NULL;
            }

            if (ahi_port != NULL) {
                DeleteMsgPort(ahi_port);
                ahi_port = NULL;
            }

            AHIBase = NULL;
            ready = FALSE;

            goto wait_for_resume;
        }

        // Resume sound output
        if (sigs & (1UL << resume_sig)) {
            if (ahi_ctrl != NULL) {
                FrodoFRFTrace("SID resume: already has AHI");
                AHI_ControlAudio(ahi_ctrl, AHIC_Play, TRUE, TAG_DONE);
            } else {
                FrodoFRFTrace("SID resume: retry AHI");
                goto retry_audio;
            }
        }

        // Calculate next buffer
        if ((sigs & (1UL << ahi_sig)) && ready && ahi_ctrl != NULL)
            calc_buffer((int16 *)(sample[play_buf].ahisi_Address), sample[play_buf].ahisi_Length * 2);
    }

audio_failed:
    /*
     * FRF 2026:
     * Sound init failed, usually because another instance owns AHI.
     * Clean up partial state, wake main task, then wait for resume/focus gain.
     */
    FrodoFRFTrace("SID audio_failed: cleanup and wait for resume");

    if (ahi_ctrl != NULL) {
        AHI_ControlAudio(ahi_ctrl, AHIC_Play, FALSE, TAG_DONE);
        AHI_FreeAudio(ahi_ctrl);
        ahi_ctrl = NULL;
    }

    if (device_open && ahi_io != NULL) {
        CloseDevice((struct IORequest *)ahi_io);
        device_open = FALSE;
    }

    if (ahi_io != NULL) {
        DeleteIORequest((struct IORequest *)ahi_io);
        ahi_io = NULL;
    }

    if (ahi_port != NULL) {
        DeleteMsgPort(ahi_port);
        ahi_port = NULL;
    }

    AHIBase = NULL;
    ready = FALSE;

wait_for_resume:
    FrodoFRFTrace("SID wait_for_resume");

    for (;;) {
        sigs = Wait((1UL << quit_sig) | (1UL << resume_sig));

        if (sigs & (1UL << quit_sig))
            goto quit;

        if (sigs & (1UL << resume_sig)) {
            FrodoFRFTrace("SID wait_for_resume: resume received");
            goto retry_audio;
        }
    }

quit:
    // Free everything
    FrodoFRFTrace("SID quit cleanup");

    if (ahi_ctrl != NULL) {
        AHI_ControlAudio(ahi_ctrl, AHIC_Play, FALSE, TAG_DONE);
        AHI_FreeAudio(ahi_ctrl);
        ahi_ctrl = NULL;
    }

    if (device_open && ahi_io != NULL) {
        CloseDevice((struct IORequest *)ahi_io);
        device_open = FALSE;
    }

    if (sample[0].ahisi_Address != NULL) {
            FreeVec(sample[0].ahisi_Address);
            sample[0].ahisi_Address = NULL;
    }
    if (sample[1].ahisi_Address != NULL) {
            FreeVec(sample[1].ahisi_Address);
            sample[1].ahisi_Address = NULL;
    }

    if (ahi_io != NULL) {
        DeleteIORequest((struct IORequest *)ahi_io);
        ahi_io = NULL;
    }

    if (ahi_port != NULL) {
        DeleteMsgPort(ahi_port);
        ahi_port = NULL;
    }

    if (quit_sig >= 0)
            FreeSignal(quit_sig);
    if (pause_sig >= 0)
            FreeSignal(pause_sig);
    if (resume_sig >= 0)
            FreeSignal(resume_sig);
    if (ahi_sig >= 0)
            FreeSignal(ahi_sig);

    // Quit synchronized with main task
    Forbid();
    Signal(main_task, 1UL << main_sig);
}


/*
 *  AHI sound callback, play next buffer and signal sub-process
 */

ULONG DigitalRenderer::sound_func(void)
{
	register struct AHIAudioCtrl *ahi_ctrl asm ("a2");
	DigitalRenderer *r = (DigitalRenderer *)ahi_ctrl->ahiac_UserData;
	r->play_buf ^= 1;
	AHI_SetSound(0, r->play_buf, 0, 0, ahi_ctrl, 0);
        if (r->sound_process != NULL && r->ahi_sig >= 0)
                Signal(&(r->sound_process->pr_Task), 1UL << r->ahi_sig);
	return 0;
}


/*
 *  Renderer for SID card
 */

// Renderer class
class SIDCardRenderer : public SIDRenderer {
public:
	SIDCardRenderer();
	virtual ~SIDCardRenderer();

	virtual void Reset(void);
	virtual void EmulateLine(void) {}
	virtual void WriteRegister(uint16 adr, uint8 byte);
	virtual void NewPrefs(Prefs *prefs) {}
	virtual void Pause(void) {}
	virtual void Resume(void) {}

private:
	UBYTE *sid_base;	// SID card base pointer
};

// Constructor: Reset SID
SIDCardRenderer::SIDCardRenderer()
{
	sid_base = (UBYTE *)0xa00001;
	Reset();
}

// Destructor: Reset SID
SIDCardRenderer::~SIDCardRenderer()
{
	Reset();
}

// Reset SID
void SIDCardRenderer::Reset(void)
{
	WaitTOF();
	ciaa.ciapra |= CIAF_LED;
	WaitTOF();
	ciaa.ciapra &= ~CIAF_LED;
}

// Write to register
void SIDCardRenderer::WriteRegister(uint16 adr, uint8 byte)
{
	sid_base[adr << 1] = byte;
}
