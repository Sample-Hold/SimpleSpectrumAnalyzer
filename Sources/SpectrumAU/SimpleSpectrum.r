#include <AudioUnit/AudioUnit.r>

#include "SimpleSpectrumVersion.h"

// Note that resource IDs must be spaced 2 apart for the 'STR ' name and description
#define kAudioUnitResID_Filter				1000

#define RES_ID			kAudioUnitResID_Filter
#define COMP_TYPE		'auol'
#define COMP_SUBTYPE	'SPCT'
#define COMP_MANUF		'FRED'
#define VERSION			kSpectrumAnalyzerVersion
#define NAME			"Fred G: SimpleSpectrumAnalyzer (carbon)"
#define DESCRIPTION		"Simple Spectrum Analyzer (carbon)"
#define ENTRY_POINT		"SimpleSpectrumEntry"

#include "AUResources.r"