/*
 * Cocos2D-SpriteBuilder: http://cocos2d.spritebuilder.com
 *
 * Copyright (c) 2015 Andy Korth or Cocos2D Authors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <Cocoa/Cocoa.h>
#import "CCWwise.h"

// C++ shit
#include <cmath>
#include <cstdio>
#include <cassert>

// Apparently wwise needs these
#include <AvailabilityMacros.h>
#include <AudioToolbox/AudioToolbox.h>

#include <CoreAudio/CoreAudioTypes.h>
#include <AK/SoundEngine/Common/AkTypes.h>
#include <AK/Tools/Common/AkPlatformFuncs.h>

// No sensible defaults, so I provide my own sensible defaults.
namespace AK
{
    void * AllocHook( size_t in_size )
    {
        return malloc( in_size );
    }
    void FreeHook( void * in_ptr )
    {
        free( in_ptr );
    }
}

// Gotta add more shit to config the init.
#include <AK/SoundEngine/Common/AkMemoryMgr.h>		// Memory Manager
#include <AK/SoundEngine/Common/AkModule.h>			// Default memory and stream managers

#include <AK/SoundEngine/Common/IAkStreamMgr.h>		// Streaming Manager
#include <AK/SoundEngine/Common/AkSoundEngine.h>    // Sound engine
#include <AK/MusicEngine/Common/AkMusicEngine.h>	// Music Engine
#include <AK/SoundEngine/Common/AkStreamMgrModule.h>	// AkStreamMgrModule

// The only one MY code needs.
#import "CCNode.h"

// needed for CAkFilePackageLowLevelIOBlocking definition.
#include "AkDefaultIOHookBlocking.h"
#include "AkFilePackageLowLevelIOBlocking.h"

@implementation CCWwise {
    /// We're using the default Low-Level I/O implementation that's part
    /// of the SDK's sample code, with the file package extension
    CAkFilePackageLowLevelIOBlocking* m_pLowLevelIO;
}

static CCWwise *shared;

+(instancetype)alloc
{
    NSAssert(shared == nil, @"Attempted to allocate a second instance of a singleton.");
    return [super alloc];
}

#define DEFAULT_POOL_SIZE 2*1024*1024
#define LENGINE_DEFAULT_POOL_SIZE 1*1024*1024

+ (CCWwise *) sharedManager{
    if (!shared){
        shared = [[self alloc] init];
        
        shared->m_pLowLevelIO = new CAkFilePackageLowLevelIOBlocking();
        
        AkMemSettings memSettings;
        AkStreamMgrSettings stmSettings;
        AkDeviceSettings deviceSettings;
        AkInitSettings initSettings;
        AkPlatformInitSettings platformInitSettings;
        AkMusicSettings musicInit;
        
        memSettings.uMaxNumPools = 20;
        AK::StreamMgr::GetDefaultSettings( stmSettings );
        AK::StreamMgr::GetDefaultDeviceSettings( deviceSettings );
        AK::SoundEngine::GetDefaultInitSettings( initSettings );
        
        initSettings.uDefaultPoolSize = DEFAULT_POOL_SIZE;

        AK::SoundEngine::GetDefaultPlatformInitSettings( platformInitSettings );
        platformInitSettings.uLEngineDefaultPoolSize = LENGINE_DEFAULT_POOL_SIZE;
        
        AK::MusicEngine::GetDefaultInitSettings( musicInit );
        
        UInt32 g_uSamplesPerFrame = initSettings.uNumSamplesPerFrame;
        
        AKRESULT res = AK::MemoryMgr::Init( &memSettings );
        if ( res != AK_Success )
        {
            NSLog(@"AK::MemoryMgr::Init() returned AKRESULT %d", res );
            abort();
        }
        
        // this isn't optional
        if ( !AK::StreamMgr::Create( stmSettings ) )
        {
            NSLog(@"AK::StreamMgr::Create() failed" );
            abort();
        }
        
        // this is for resolving files or something
        res = shared->m_pLowLevelIO->Init( deviceSettings );
        if ( res != AK_Success )
        {
            NSLog(@"m_lowLevelIO.Init() returned AKRESULT %d", res );
            abort();
        }

        // This is where the magic happens. Really it should be the only one call needed
        res = AK::SoundEngine::Init( &initSettings, &platformInitSettings );
        if ( res != AK_Success )
        {
            NSLog(@"AK::SoundEngine::Init() returned AKRESULT %d", res );
            abort();
        }
        
        res = AK::MusicEngine::Init( &musicInit );
        if ( res != AK_Success )
        {
            NSLog(@"Could not initialize the Music Engine returned AKRESULT %d", res );
            abort();
        }
        
        
        
//        shared->m_pLowLevelIO->SetBasePath("./");
        shared->m_pLowLevelIO->SetBasePath("./cocos2d-tests-mac.app/Contents/Resources/Resources-shared/WwiseContent/");
        
        // Set global language. Low-level I/O devices can use this string to find language-specific assets.
        // even though I don't care
        if ( AK::StreamMgr::SetCurrentLanguage( AKTEXT( "English(US)" ) ) != AK_Success )
        {
            NSLog(@"couldn't set language but I don't care" );
        }
        NSLog(@"Successfully started wwise.");
    }
    
    return shared;
}

- (void) terminate
{
    NSLog(@"terminating sound engine.");
    
    AK::MusicEngine::Term();
    AK::SoundEngine::Term();
    
    // CAkFilePackageLowLevelIOBlocking::Term() destroys its associated streaming device
    // that lives in the Stream Manager, and unregisters itself as the File Location Resolver.
    m_pLowLevelIO->Term();
    
    if ( AK::IAkStreamMgr::Get() )
        AK::IAkStreamMgr::Get()->Destroy();
    
    // Terminate the Memory Manager
    AK::MemoryMgr::Term();
}

- (void) RenderAudio
{
    AK::SoundEngine::RenderAudio();
}

// now my shit is here
- (void) registerGameObject:(CCNode *) n
{
     AK::SoundEngine::RegisterGameObj( (AkGameObjectID) n, [n.name UTF8String] );
}

- (void) postEvent:(NSString *) eventName forGameObject:(CCNode *) n
{
    AK::SoundEngine::PostEvent( [eventName UTF8String], (AkGameObjectID) n );
}

- (BOOL) loadBank:(NSString *)soundBankFile
{
    AkBankID bankID;
    if ( AK::SoundEngine::LoadBank( [soundBankFile UTF8String], AK_DEFAULT_POOL_ID, bankID ) != AK_Success )
    {
        CCLOG(@"Failed loading sound bank %@", soundBankFile);
        return false;
    }
    return true;
}

@end
