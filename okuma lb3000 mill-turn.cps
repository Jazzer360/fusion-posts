/**
  Copyright (C) 2012-2026 by Autodesk, Inc.
  All rights reserved.

  Okuma LB3000 Lathe post processor configuration.

  $Revision: 44210 aab7925640b48c5f8f0e2cc46a4d4c4f8555a5e6 $
  $Date: 2026-01-20 22:37:45 $

  FORKID {D93DAA65-1C09-402E-9871-3280B561D994}
*/

///////////////////////////////////////////////////////////////////////////////
//                        MANUAL NC COMMANDS
//
// The following ACTION commands are supported by this post.
//
//     partEject                  - Manually eject the part
//     usePolarInterpolation      - Force Polar interpolation mode for next operation (usePolarMode is deprecated but still supported)
//     usePolarCoordinates        - Force Polar coordinates for the next operation (useXZCMode is deprecated but still supported)
//
///////////////////////////////////////////////////////////////////////////////

description = "Okuma LB3000 with OSP-300 control";
vendor = "OKUMA";
vendorUrl = "http://www.okuma.com";
legal = "Copyright (C) 2012-2026 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45909;

longDescription = "Okuma LB3000 lathe (OSP-300 control) post with support for mill-turn.";

extension = "min";
programNameIsInteger = false;
setCodePage("ascii");

capabilities = CAPABILITY_MILLING | CAPABILITY_TURNING;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(90); // reduced sweep to break up circular moves on quadrant boundaries
allowHelicalMoves = true;
allowedCircularPlanes = undefined; // allow any circular motion
allowSpiralMoves = false;
allowFeedPerRevolutionDrilling = true;
highFeedrate = (unit == IN) ? 100 : 2500;

// user-defined properties
properties = {
  gotSecondarySpindle: {
    title      : "Got secondary spindle",
    description: "Specifies if the machine has a secondary spindle.",
    group      : "configuration",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  // CUSTOM: tool-based bar puller (no secondary spindle required)
  useToolBarPuller: {
    title      : "Use tool-based bar puller",
    description: "Handle bar-pull cycles with a tool that has bar-pulling fingers instead of a secondary spindle. The puller tool's X offset must be set so that commanding X0 places the fingers at the ideal grip position on the bar. The Z offset is calibrated normally (program Z matches the part WCS). The actual grip Z is computed at post time from the tracked minimum machined Z plus 'Bar puller Z offset'.",
    group      : "barPuller",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  toolBarPullerNumber: {
    title      : "Bar puller tool number",
    description: "Tool number of the bar pulling tool to activate during bar-pull cycles. The tool's offset register is assumed to match its number (e.g. tool 6 -> T060606).",
    group      : "barPuller",
    type       : "integer",
    range      : [1, 99],
    value      : 7,
    scope      : "post"
  },
  barPullerZOffset: {
    title      : "Bar puller Z offset",
    description: "Z offset of the bar puller grip position relative to the start of the unmachined stock (the chuck-side boundary of the deepest previously-machined feature, tracked automatically by the post). Typically zero or slightly negative to grip a hair into the unmachined region. Positive values grip further out (toward the tailstock), negative values grip closer to the chuck.",
    group      : "barPuller",
    type       : "spatial",
    value      : 0,
    scope      : "post"
  },
  // CUSTOM: configurable turning-mode entry code (G270 / M109 / none)
  turningModeCommand: {
    title      : "Turning-mode entry code",
    description: "Code emitted at the start of turning sections to ensure the machine is in turning mode. 'G270' is the modern Okuma enter-turning-mode G code. Older Okuma controls (e.g. LB15-II) do not support G270 -- instead choose 'M109' so the C-axis is explicitly disabled (which is what is actually required for the spindle to rotate freely). Choose 'None' to suppress this output entirely.",
    group      : "preferences",
    type       : "enum",
    values     : [
      {title:"G270 (modern Okuma)", id:"g270"},
      {title:"M109 (disable C-axis)", id:"m109"},
      {title:"None", id:"none"}
    ],
    value      : "m109",
    scope      : "post"
  },
  // CUSTOM: spindle gear-range output (M41 low / M42 high)
  useGearRanges: {
    title      : "Output spindle gear-range codes",
    description: "When on, emits an M41/M42 gear-range code alongside each spindle-on block. M41 (low range) is used for live-tool sections (milling and off-center / indexed drilling). M42 (high range) is used for everything spun on the main spindle, including on-center drilling. Leave off for machines without selectable gear ranges.",
    group      : "preferences",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  // CUSTOM: force feed-per-revolution (G95) on drilling sections
  feedPerRevForDrilling: {
    title      : "Feed per revolution for drilling",
    description: "When on, drilling cycles are posted in feed-per-revolution (G95) mode regardless of the Fusion operation's feed-mode setting. The cutting feedrate from Fusion (in/min or mm/min) is converted to per-rev by dividing by spindle RPM at post time. This lets you tweak spindle speed at the control without invalidating the feed.",
    group      : "preferences",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  xAxisMinimum: {
    title      : "X-axis minimum limit",
    description: "Defines the lower limit of X-axis travel as a radius value.",
    group      : "configuration",
    type       : "spatial",
    range      : [-99999, 0],
    value      : 0,
    scope      : "post"
  },
  usePartCatcher: {
    title      : "Use part catcher",
    description: "Specifies whether part catcher code should be output.",
    group      : "configuration",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  gotChipConveyor: {
    title       : "Got chip conveyor",
    description : "Specifies whether to use a chip conveyor.",
    group       : "configuration",
    type        : "boolean",
    presentation: "yesno",
    value       : false,
    scope       : "post"
  },
  maxTool: {
    title      : "Max tool number",
    description: "Defines the maximum tool number.",
    group      : "configuration",
    type       : "integer",
    range      : [0, 999999999],
    value      : 12,
    scope      : "post"
  },
  maxToolOffset: {
    title      : "Max tool offset number",
    description: "Defines the maximum tool offset number.",
    group      : "configuration",
    type       : "integer",
    range      : [0, 999999999],
    value      : 96,
    scope      : "post"
  },
  maximumSpindleSpeed: {
    title      : "Max spindle speed",
    description: "Defines the maximum spindle speed allowed by your machines.",
    group      : "configuration",
    type       : "integer",
    range      : [0, 999999999],
    value      : 3500,
    scope      : "post"
  },
  showSequenceNumbers: {
    title      : "Use sequence numbers",
    description: "'Yes' outputs sequence numbers on each block, 'Only on tool change' outputs sequence numbers on tool change blocks only, and 'No' disables the output of sequence numbers.",
    group      : "formats",
    type       : "enum",
    values     : [
      {title:"Yes", id:"true"},
      {title:"No", id:"false"},
      {title:"Only on tool change", id:"toolChange"}
    ],
    value: "toolChange",
    scope: "post"
  },
  sequenceNumberStart: {
    title      : "Start sequence number",
    description: "The number at which to start the sequence numbers.",
    group      : "formats",
    type       : "integer",
    value      : 1,
    scope      : "post"
  },
  sequenceNumberIncrement: {
    title      : "Sequence number increment",
    description: "The amount by which the sequence number is incremented by in each block.",
    group      : "formats",
    type       : "integer",
    value      : 1,
    scope      : "post"
  },
  useRadius: {
    title      : "Radius arcs",
    description: "If yes is selected, arcs are outputted using radius values rather than IJK.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useCycles: {
    title      : "Use cycles",
    description: "Specifies if canned drilling cycles should be used.",
    group      : "preferences",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  optionalStop: {
    title      : "Optional stop",
    description: "Outputs optional stop code during when necessary in the code.",
    group      : "preferences",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  useParametricFeed: {
    title      : "Parametric feed",
    description: "Specifies the feed value that should be output using a Q value.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  autoEject: {
    title      : "Auto eject",
    description: "Specifies whether the part should automatically eject at the end of a program.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useTailStock: {
    title       : "Use tailstock",
    description : "Specifies whether to use the tailstock or not.",
    group       : "configuration",
    type        : "boolean",
    presentation: "yesno",
    value       : false,
    scope       : "post"
  },
  homePositionX: {
    title      : "X home position in radius",
    description: "X home position specified in radius.",
    group      : "homePositions",
    type       : "spatial",
    value      : 15,
    scope      : "post"
  },
  homePositionY: {
    title      : "Y home position",
    description: "Y home position.",
    group      : "homePositions",
    type       : "spatial",
    value      : 0,
    scope      : "post"
  },
  homePositionZ: {
    title      : "Z home position",
    description: "Z home position.",
    group      : "homePositions",
    type       : "spatial",
    value      : 5,
    scope      : "post"
  },
  homePositionW: {
    title      : "W home position",
    description: "W home position.",
    group      : "homePositions",
    type       : "spatial",
    value      : 0,
    scope      : "post"
  },
  transferUseTorque: {
    title      : "Stock-transfer torque control",
    description: "Use torque control for stock transfer.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  optimizeCAxisSelect: {
    title      : "Optimize C axis selection",
    description: "Optimizes the output of enable/disable C-axis codes.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useSimpleThread: {
    title      : "Use simple threading cycle",
    description: "Enable to output G33 simple threading cycle, disable to output G71 standard threading cycle.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useYAxisForDrilling: {
    title      : "Position in Y for axial drilling",
    description: "Positions in Y for axial drilling options when it can instead of using the C-axis.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  // CUSTOM: declare whether the machine actually has a Y-axis (turret 1)
  gotYAxis: {
    title      : "Has Y-axis (turret 1)",
    description: "Set to false on machines without a Y-axis (e.g. older Okuma lathes). When off, the post will not emit G138 / Y-axis Cartesian mode and will keep X in diameter mode for live-tool sections. Toolpaths that require actual Y-axis travel will error out.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  writeVersion: {
    title      : "Write version",
    description: "Write the version number in the header of the code.",
    group      : "formats",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  separateWordsWithSpace: {
    title      : "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    group      : "formats",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  showNotes: {
    title      : "Show notes",
    description: "Writes operation notes as comments in the outputted code.",
    group      : "formats",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  writeMachine: {
    title      : "Write machine",
    description: "Output the machine settings in the header of the code.",
    group      : "formats",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  writeTools: {
    title      : "Write tool list",
    description: "Output a tool list in the header of the code.",
    group      : "formats",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useShortestDirection: {
    title      : "Use C-axis shortest direction code",
    description: "Specifies that an M960 should be used to control the C-axis direction instead of the M15/M16 directional codes.",
    group      : "multiAxis",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  safeStartAllOperations: {
    title      : "Safe start all operations",
    description: "Write optional blocks at the beginning of all operations that include all commands to start program.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  loadMonitoring: {
    title      : "Load monitoring",
    description: "A value that enables which axes should be monitored.  1 = X, 2 = Z, 3 = XZ, etc.",
    group      : "preferences",
    type       : "integer",
    range      : [0, 1013],
    value      : 0,
    scope      : "post"
  }
};

// wcs definiton
wcsDefinitions = {
  useZeroOffset: false,
  wcs          : [
    {name:"Standard", format:"#", range:[1, 1]}
  ]
};

var singleLineCoolant = false; // specifies to output multiple coolant codes in one line rather than in separate lines
// samples:
// {id: COOLANT_THROUGH_TOOL, on: 88, off: 89}
// {id: COOLANT_THROUGH_TOOL, on: [8, 88], off: [9, 89]}
// {id: COOLANT_THROUGH_TOOL, turret1:{on: [8, 88], off:[9, 89]}, turret2:{on:88, off:89}}
// {id: COOLANT_THROUGH_TOOL, spindle1:{on: [8, 88], off:[9, 89]}, spindle2:{on:88, off:89}}
// {id: COOLANT_THROUGH_TOOL, spindle1t1:{on: [8, 88], off:[9, 89]}, spindle1t2:{on:88, off:89}}
// {id: COOLANT_THROUGH_TOOL, on: "M88 P3 (myComment)", off: "M89"}
var coolants = [
  {id:COOLANT_FLOOD, on:8},
  {id:COOLANT_MIST},
  {id:COOLANT_THROUGH_TOOL, on:143, off:142},
  {id:COOLANT_AIR, spindle1:{on:51, off:50}, spindle2:{on:288, off:289}},
  {id:COOLANT_AIR_THROUGH_TOOL},
  {id:COOLANT_SUCTION},
  {id:COOLANT_FLOOD_MIST},
  {id:COOLANT_FLOOD_THROUGH_TOOL},
  {id:COOLANT_OFF, off:9}
];

var permittedCommentChars = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,=_-/";

var gFormat = createFormat({prefix:"G", decimals:0});
var mFormat = createFormat({prefix:"M", decimals:0});
var spatialFormat = createFormat({decimals:(unit == MM ? 3 : 4), type:FORMAT_REAL});
var integerFormat = createFormat({decimals:0});
var xFormat = createFormat({decimals:(unit == MM ? 3 : 4), type:FORMAT_REAL, scale:2}); // diameter mode
var yFormat = createFormat({decimals:(unit == MM ? 3 : 4), type:FORMAT_REAL});
var zFormat = createFormat({decimals:(unit == MM ? 3 : 4), type:FORMAT_REAL});
var rFormat = createFormat({decimals:(unit == MM ? 3 : 4), type:FORMAT_REAL}); // radius
var abcFormat = createFormat({decimals:3, type:FORMAT_REAL, scale:DEG});
var bFormat = createFormat({prefix:"(B=", suffix:")", decimals:3, type:FORMAT_REAL, scale:DEG});
var cFormat = createFormat({decimals:3, type:FORMAT_REAL, scale:DEG});
var fpmFormat = createFormat({decimals:(unit == MM ? 2 : 3), type:FORMAT_REAL});
var fprFormat = createFormat({type:FORMAT_REAL, decimals:(unit == MM ? 3 : 4), minimum:(unit == MM ? 0.001 : 0.0001)});
var feedFormat = fpmFormat;
var pitchFormat = createFormat({decimals:6, type:FORMAT_REAL});
var toolFormat = createFormat({decimals:0, minDigitsLeft:4});
var tool1Format = createFormat({decimals:0, minDigitsLeft:6});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:2, type:FORMAT_REAL}); // seconds - range 0.001-99999.999
var dwellFormat = createFormat({prefix:"F", decimals:2, type:FORMAT_REAL}); // seconds - range 0.001-99999.999
var taperFormat = createFormat({decimals:1, scale:DEG});
var oFormat = createFormat({decimals:0, minDigitsLeft:4});

var xOutput = createOutputVariable({prefix:"X"}, xFormat);
var yOutput = createOutputVariable({prefix:"Y"}, yFormat);
var zOutput = createOutputVariable({prefix:"Z"}, zFormat);
var wOutput = createOutputVariable({prefix:"W"}, zFormat);
var aOutput = createOutputVariable({prefix:"A"}, abcFormat);
var bOutput = createOutputVariable({}, bFormat);
var cOutput = createOutputVariable({prefix:"C", cyclicLimit:360}, cFormat);
var feedOutput = createOutputVariable({prefix:"F"}, feedFormat);
var pitchOutput = createOutputVariable({prefix:"F", control:CONTROL_FORCE}, pitchFormat);
var sOutput = createOutputVariable({prefix:"S", control:CONTROL_FORCE}, rpmFormat);
var sbOutput = createOutputVariable({prefix:"SB=", control:CONTROL_FORCE}, rpmFormat);
var maxSpeedOutput = createOutputVariable({prefix:"S", control:CONTROL_FORCE}, rpmFormat);
var eOutput = createOutputVariable({prefix:"E", control:CONTROL_FORCE}, secFormat);
var rOutput = createOutputVariable({prefix:"R", control:CONTROL_FORCE}, rFormat);

// circular output
var iOutput = createOutputVariable({prefix:"I", control:CONTROL_NONZERO}, spatialFormat);
var jOutput = createOutputVariable({prefix:"J", control:CONTROL_NONZERO}, spatialFormat);
var kOutput = createOutputVariable({prefix:"K", control:CONTROL_NONZERO}, spatialFormat);

var gMotionModal = createOutputVariable({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createOutputVariable({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gFeedModeModal = createOutputVariable({}, gFormat); // modal group 5 // G98-99
var gSpindleModeModal = createOutputVariable({}, gFormat); // modal group 5 // G96-97
var gSpindleModal = createOutputVariable({}, mFormat); // M176/177 SPINDLE MODE
var gAbsIncModal = createOutputVariable({}, gFormat); // modal group 6 // G90-91
var gCycleModal = createOutputVariable({}, gFormat); // modal group 9 // G81, ...
var gPolarModal = createOutputVariable({}, gFormat); // G137, G136
var gYaxisModal = createOutputVariable({}, gFormat);
var cAxisBrakeModal = createOutputVariable({}, mFormat);
var mInterferModal = createOutputVariable({}, mFormat);
var cAxisEngageModal = createOutputVariable({}, mFormat);
var cAxisDirectionModal = createOutputVariable({}, mFormat);
var gSelectSpindleModal = createOutputVariable({}, gFormat);
var tailStockModal = createOutputVariable({}, mFormat);

// fixed settings
var firstFeedParameter = 100;
var airCleanChuck = true; // use air to clean off chuck at part transfer and part eject

// defined in defineMachine
var turret1GotYAxis;
var turret2GotYAxis;
var turret1GotBAxis;
var gotYAxis;
var yAxisMinimum;
var yAxisMaximum;
var xAxisMinimum;
var gotBAxis;
var bAxisIsManual;
var gotMultiTurret;
var gotPolarInterpolation;
var gotSecondarySpindle;
var gotDoorControl;
var maximumSpindleSpeedLive;

var WARNING_TURRET_UNSPECIFIED = 0;

var SPINDLE_MAIN = 0;
var SPINDLE_SUB = 1;
var SPINDLE_LIVE = 2;

var POSX = 0;
var POXY = 1;
var POSZ = 2;
var NEGZ = -2;

var TRANSFER_PHASE = 0;
var TRANSFER_SPEED = 1;
var TRANSFER_STOP = 2;

// getSpindle parameters
var TOOL = false;
var PART = true;

// collected state
var sequenceNumber;
var currentWorkOffset;
var optionalSection = false;
var forceSpindleSpeed = false;
var activeMovements; // do not use by default
var currentFeedId;
var previousSpindle = SPINDLE_MAIN;
var activeSpindle = SPINDLE_MAIN;
var partCutoff = false;
var reverseTap = false;
var showSequenceNumbers;
var forcePolarCoordinates = false; // forces Polar coordinates output, activated by Action:usePolarCoordinates
var forcePolarInterpolation = false; // force Polar interpolation, activated by Action:usePolarInterpolation
var tapping = false;
var ejectRoutine = false;
var bestABC = undefined;
var lastSpindleMode = undefined;
// CUSTOM: last gear-range M-code (41 or 42) actually emitted, so we can
// suppress a redundant M41/M42 when the gear hasn't changed. Reset in onOpen.
var lastEmittedGear = undefined;
var lastSpindleSpeed = 0;
var lastSpindleDirection = undefined;
var operationNeedsSafeStart = false; // used to convert blocks to optional for safeStartAllOperations
var vlmon; // load monitoring variable
var previousMaximumSpeed = 0;

var machineState = {
  isTurningOperation            : undefined,
  liveToolIsActive              : undefined,
  cAxisIsEngaged                : undefined,
  machiningDirection            : undefined,
  mainSpindleIsActive           : undefined,
  subSpindleIsActive            : undefined,
  mainSpindleBrakeIsActive      : undefined,
  subSpindleBrakeIsActive       : undefined,
  tailstockIsActive             : false,
  usePolarInterpolation         : false,
  usePolarCoordinates           : false,
  axialCenterDrilling           : false,
  currentBAxisOrientationTurning: new Vector(0, 0, 0),
  mainChuckIsClamped            : undefined,
  subChuckIsClamped             : undefined,
  spindlesAreAttached           : false,
  spindlesAreSynchronized       : false,
  stockTransferIsActive         : false,
  cAxesAreSynchronized          : false,
  feedPerRevolution             : undefined
};

/** G/M codes setup */
function getCode(code, spindle) {
  switch (code) {
  case "PART_CATCHER_ON":
    return 77;
  case "PART_CATCHER_OFF":
    return 76;
  case "TAILSTOCK_ON":
    machineState.tailstockIsActive = true;
    return 21;
  case "TAILSTOCK_OFF":
    machineState.tailstockIsActive = false;
    return 20;
  case "SET_SPINDLE_FRAME":
    break;
  case "ENABLE_Y_AXIS":
    setRadiusDiameterMode("radius");
    return 138;
  case "DISABLE_Y_AXIS":
    setRadiusDiameterMode("diameter");
    return 136;
  case "ENABLE_C_AXIS":
    machineState.cAxisIsEngaged = true;
    return 110;
  case "DISABLE_C_AXIS":
    machineState.cAxisIsEngaged = false;
    return 109;
  case "POLAR_INTERPOLATION_ON":
    return 137;
  case "POLAR_INTERPOLATION_OFF":
    return 136;
  case "ENABLE_TURNING":
    return 270;
  case "STOP_SPINDLE":
    switch (spindle) {
    case SPINDLE_MAIN:
      machineState.mainSpindleIsActive = false;
      return 5;
    case SPINDLE_SUB:
      machineState.subSpindleIsActive = false;
      return 5;
    case SPINDLE_LIVE:
      machineState.liveToolIsActive = false;
      return 12;
    }
    break;
  case "ORIENT_SPINDLE":
    return (spindle == SPINDLE_MAIN) ? 19 : 239;
  case "START_SPINDLE_CW":
    switch (spindle) {
    case SPINDLE_MAIN:
      machineState.mainSpindleIsActive = true;
      machineState.subSpindleIsActive = false;
      machineState.liveToolIsActive = false;
      return 3;
    case SPINDLE_SUB:
      machineState.mainSpindleIsActive = false;
      machineState.subSpindleIsActive = true;
      machineState.liveToolIsActive = false;
      return 3;
    case SPINDLE_LIVE:
      machineState.mainSpindleIsActive = false;
      machineState.subSpindleIsActive = false;
      machineState.liveToolIsActive = true;
      return 13;
    }
    break;
  case "START_SPINDLE_CCW":
    switch (spindle) {
    case SPINDLE_MAIN:
      machineState.mainSpindleIsActive = true;
      machineState.subSpindleIsActive = false;
      machineState.liveToolIsActive = false;
      return 4;
    case SPINDLE_SUB:
      machineState.mainSpindleIsActive = false;
      machineState.subSpindleIsActive = true;
      machineState.liveToolIsActive = false;
      return 4;
    case SPINDLE_LIVE:
      machineState.mainSpindleIsActive = false;
      machineState.subSpindleIsActive = false;
      machineState.liveToolIsActive = true;
      return 14;
    }
    break;
  case "FEED_MODE_UNIT_REV":
    machineState.feedPerRevolution = true;
    return 95;
  case "FEED_MODE_UNIT_MIN":
    machineState.feedPerRevolution = false;
    return 94;
  case "CONSTANT_SURFACE_SPEED_ON":
    return 96;
  case "CONSTANT_SURFACE_SPEED_OFF":
    return 97;
  case "AUTO_AIR_ON":
    break;
  case "AUTO_AIR_OFF":
    break;
  case "LOCK_MULTI_AXIS":
    return 147;
  case "UNLOCK_MULTI_AXIS":
    return 146;
  case "C_AXIS_CW":
    return 15;
  case "C_AXIS_CCW":
    return 16;
  case "CLAMP_CHUCK":
    return (spindle == SPINDLE_MAIN) ? 83 : 248;
  case "UNCLAMP_CHUCK":
    return (spindle == SPINDLE_MAIN) ? 84 : 249;
  case "SPINDLE_SYNCHRONIZATION_PHASE":
    break;
  case "SPINDLE_SYNCHRONIZATION_SPEED":
    return 151;
  case "SPINDLE_SYNCHRONIZATION_OFF":
    return 150;
  case "IGNORE_SPINDLE_ORIENTATION":
    return 210;
  case "TORQUE_LIMIT_ON":
    return 29;
  case "TORQUE_LIMIT_OFF":
    return 28;
  case "TORQUE_SKIP_ON":
    return 22;
  case "SELECT_SPINDLE":
    switch (spindle) {
    case SPINDLE_MAIN:
      return 140;
    case SPINDLE_SUB:
      return 141;
    }
    break;
  case "RIGID_TAPPING":
    break;
  case "INTERNAL_INTERLOCK_ON":
    return (spindle == SPINDLE_MAIN) ? 185 : 247;
  case "INTERNAL_INTERLOCK_OFF":
    return (spindle == SPINDLE_MAIN) ? 184 : 246;
  case "INTERFERENCE_CHECK_OFF":
    break;
  case "INTERFERENCE_CHECK_ON":
    break;
  case "CYCLE_PART_EJECTOR":
    break;
  case "AIR_BLAST_ON":
    return (spindle == SPINDLE_MAIN) ? 51 : 288;
  case "AIR_BLAST_OFF":
    return (spindle == SPINDLE_MAIN) ? 50 : 289;
  default:
    error(localize("Command " + code + " is not defined."));
    return 0;
  }
  return 0;
}

/**  Returns the desired tolerance for the given section in MM.*/
function getTolerance() {
  var t1 = toPreciseUnit(tolerance, MM);
  var t2 = getParameter("operation:tolerance", t1);
  t1 = t1 > 0 ? Math.min(t1, t2) : t2;
  return unit == IN ? t1 * 25.4 : t1;
}

/**
  Outputs the C-axis direction code.
*/
function setCAxisDirection(previous, current) {
  if (!getProperty("useShortestDirection")) {
    var delta = current - previous;

    if (((delta < 0) && (delta > -Math.PI)) || (delta > Math.PI)) {
      writeBlock(cAxisDirectionModal.format(getCode("C_AXIS_CCW", getSpindle(PART))));
    } else if (abcFormat.getResultingValue(delta) != 0) {
      writeBlock(cAxisDirectionModal.format(getCode("C_AXIS_CW", getSpindle(PART))));
    }
  }
}

function formatSequenceNumber() {
  if (sequenceNumber > 99999) {
    sequenceNumber = getProperty("sequenceNumberStart");
  }
  var seqno = "N" + sequenceNumber;
  sequenceNumber += getProperty("sequenceNumberIncrement");
  return seqno;
}

/**
  Writes the specified block.
*/
function writeBlock() {
  var text = formatWords(arguments);
  if (!text) {
    return;
  }
  var seqno = "";
  var opskip = "";
  if (showSequenceNumbers == "true") {
    seqno = formatSequenceNumber();
  }
  if (optionalSection || skipBlocks) {
    opskip = "/";
  }

  if (text) {
    writeWords(opskip, seqno, text);
  }
  if (getProperty("showSequenceNumbers") == "toolChange") {
    showSequenceNumbers = "false";
  }
}

function formatComment(text) {
  return "(" + String(filterText(String(text).toUpperCase(), permittedCommentChars)).replace(/[()]/g, "") + ")";
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln(formatComment(text));
}

function getB(abc, section) {
  if (section.spindle == SPINDLE_PRIMARY) {
    return abc.y;
  } else {
    return Math.PI - abc.y;
  }
}

function writeCommentSeqno(text) {
  writeln(formatSequenceNumber() + formatComment(text));
}

function formatTool(tool, cancelCompensation) {
  var compensationOffset = tool.isTurningTool() ? tool.compensationOffset : tool.lengthOffset;
  var toolNumber;
  var offset1;
  var offset2;
  if (cancelCompensation) {
    offset1 = 0;
    offset2 = 0;
  } else if (tool.isTurningTool()) {
    offset1 = compensationOffset;
    offset2 = compensationOffset;
  } else {
    offset1 = tool.diameterOffset;
    offset2 = tool.lengthOffset;
  }
  if (getProperty("maxToolOffset") > 99) {
    toolNumber = "T" + tool1Format.format(compensationOffset * 1000 + tool.number);
  } else {
    toolNumber = "T" + tool1Format.format(offset1 * 10000 + tool.number * 100 + offset2);
  }
  return toolNumber;
}

var skipBlocks = false;
function writeStartBlocks(isRequired, code) {
  var safeSkipBlocks = skipBlocks;
  if (!isRequired) {
    if (!getProperty("safeStartAllOperations", false)) {
      return; // when safeStartAllOperations is disabled, dont output code and return
    }
    // if values are not required, but safe start is enabled - write following blocks as optional
    skipBlocks = true;
  }
  code(); // writes out the code which is passed to this function as an argument
  skipBlocks = safeSkipBlocks; // restore skipBlocks value
}

function defineMachine() {
  gotSecondarySpindle = getProperty("gotSecondarySpindle");
  gotMultiTurret = false;
  // CUSTOM: turret 1 Y-axis presence is user-configurable (default false for LB15-II / older Okuma lathes)
  turret1GotYAxis = getProperty("gotYAxis");
  turret2GotYAxis = false;
  yAxisMinimum = toPreciseUnit(-45, MM); // specifies the minimum range for the Y-axis
  yAxisMaximum = toPreciseUnit(70, MM); // specifies the maximum range for the Y-axis
  xAxisMinimum = getProperty("xAxisMinimum"); // specifies the maximum range for the X-axis (RADIUS MODE VALUE)
  gotBAxis = false; // B-axis always requires customization to match the machine specific functions for doing rotations
  bAxisIsManual = true; // B-axis is manually set and not programmable
  gotPolarInterpolation = true; // specifies if the machine has XY polar interpolation capabilities
  gotDoorControl = false;

  // define B-axis
  if (gotBAxis) {
    if (bAxisIsManual) {
      bFormat.setPrefix("(B=");
      bFormat.setSuffix(")");
      bOutput.setFormat(bFormat);
    } else {
      bFormat.setPrefix("B");
      bFormat.setSuffix("");
      bOutput.setFormat(bFormat);
    }
  }
}

function activateMachine(section) {
  // TCP setting
  operationSupportsTCP = false;

  // handle multiple turrets
  var turret = 1;
  if (gotMultiTurret) {
    turret = section.getTool().turret;
    if (turret == 0) {
      warningOnce(localize("Turret has not been specified. Using Turret 1 as default."), WARNING_TURRET_UNSPECIFIED);
      turret = 1; // upper turret as default
    }
    turret = turret == undefined ? 1 : turret;
    switch (turret) {
    case 1:
      gotYAxis = turret1GotYAxis;
      gotBAxis = turret1GotBAxis;
      break;
    case 2:
      gotYAxis = turret2GotYAxis;
      gotBAxis = false;
      break;
    default:
      error(subst(localize("Turret %1 is not supported"), turret));
      return turret;
    }
  } else {
    gotYAxis = turret1GotYAxis;
  }

  // disable unsupported rotary axes output
  if (!gotYAxis) {
    yOutput.disable();
  }
  aOutput.disable();

  // define machine configuration
  var bAxis;
  var cAxis;
  if (section.getSpindle() == SPINDLE_PRIMARY) {
    bAxis = createAxis({coordinate:1, table:false, axis:[0, -1, 0], range:[-0.001, 90.001], preference:0, tcp:true});
    cAxis = createAxis({coordinate:2, table:true, axis:[0, 0, 1], cyclic:true, range:[0, 360], preference:0, tcp:operationSupportsTCP});
  } else {
    bAxis = createAxis({coordinate:1, table:false, axis:[0, -1, 0], range:[-0.001, 180.001], preference:0, tcp:true});
    cAxis = createAxis({coordinate:2, table:true, axis:[0, 0, 1], cyclic:true, range:[0, 360], preference:0, tcp:operationSupportsTCP});
  }
  if (gotBAxis) {
    machineConfiguration = new MachineConfiguration(bAxis, cAxis);
    bOutput.enable();
  } else {
    machineConfiguration = new MachineConfiguration(cAxis);
    bOutput.disable();
  }

  // define spindle axis
  if (!gotBAxis || bAxisIsManual || (turret == 2)) {
    if ((getMachiningDirection(section) == MACHINING_DIRECTION_AXIAL) && !section.isMultiAxis()) {
      machineConfiguration.setSpindleAxis(new Vector(0, 0, 1));
    } else {
      machineConfiguration.setSpindleAxis(new Vector(1, 0, 0));
    }
  } else {
    machineConfiguration.setSpindleAxis(new Vector(1, 0, 0)); // set the spindle axis depending on B0 orientation
  }

  // define linear axes limits
  var xAxisMaximum = 10000; // don't check X-axis maximum limit
  yAxisMinimum = gotYAxis ? yAxisMinimum : 0;
  yAxisMaximum = gotYAxis ? yAxisMaximum : 0;
  var xAxis = createAxis({actuator:"linear", coordinate:0, table:true, axis:[1, 0, 0], range:[xAxisMinimum, xAxisMaximum]});
  var yAxis = createAxis({actuator:"linear", coordinate:1, table:true, axis:[0, 1, 0], range:[yAxisMinimum, yAxisMaximum]});
  var zAxis = createAxis({actuator:"linear", coordinate:2, table:true, axis:[0, 0, 1], range:[-100000, 100000]});
  machineConfiguration.setAxisX(xAxis);
  machineConfiguration.setAxisY(yAxis);
  machineConfiguration.setAxisZ(zAxis);

  // enable retract/reconfigure
  safeRetractDistance = (unit == IN) ? 1 : 25; // additional distance to retract out of stock, can be overridden with a property
  safeRetractFeed = (unit == IN) ? 20 : 500; // retract feed rate
  safePlungeFeed = (unit == IN) ? 10 : 250; // plunge feed rate
  var stockExpansion = new Vector(toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN)); // expand stock XYZ values
  machineConfiguration.enableMachineRewinds();
  machineConfiguration.setSafeRetractDistance(safeRetractDistance);
  machineConfiguration.setSafeRetractFeedrate(safeRetractFeed);
  machineConfiguration.setSafePlungeFeedrate(safePlungeFeed);
  machineConfiguration.setRewindStockExpansion(stockExpansion);

  // multi-axis feedrates
  machineConfiguration.setMultiAxisFeedrate(
    operationSupportsTCP ? FEED_FPM : FEED_FPM, // FEED_INVERSE_TIME,
    99999, // maximum output value for dpm feed rates
    DPM_COMBINATION, // INVERSE_MINUTES/INVERSE_SECONDS or DPM_COMBINATION/DPM_STANDARD
    0.5, // tolerance to determine when the DPM feed has changed
    unit == MM ? 1.0 : 1.0 // ratio of rotary accuracy to linear accuracy for DPM calculations
  );
  var axes = [machineConfiguration.getAxisU(), machineConfiguration.getAxisV(), machineConfiguration.getAxisW()];
  if (axes.some(function(axis) {return axis.isEnabled() && axis.isTCPEnabled();})) {
    bufferRotaryMoves = false; // disable bufferRotaryMoves if TCP is enabled on any rotary axis
  }

  machineConfiguration.setVendor("OKUMA");
  machineConfiguration.setModel("LB3000");
  setMachineConfiguration(machineConfiguration);
  if (section.isMultiAxis()) {
    section.optimizeMachineAnglesByMachine(machineConfiguration, OPTIMIZE_AXIS);
  }

  return turret;
}

function onOpen() {
  if (getProperty("useRadius")) {
    maximumCircularSweep = toRad(90); // avoid potential center calculation errors for CNC
  }

  // Copy certain properties into global variables
  showSequenceNumbers = getProperty("showSequenceNumbers");

  // define machine
  defineMachine();
  turret1GotBAxis = gotBAxis;
  activeTurret = activateMachine(getSection(0));

  yOutput.disable();
  gPolarModal.format(getCode("DISABLE_Y_AXIS", true));

  if (highFeedrate <= 0) {
    error(localize("You must set 'highFeedrate' because axes are not synchronized for rapid traversal."));
    return;
  }

  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  sequenceNumber = getProperty("sequenceNumberStart");

  if (programName) {
    var programId = parseInt(programName, 10);
    if ((programId >= 1) && (programId <= 9999)) {
      writeln("O" + oFormat.format(programId));
    }
  }

  // Select the active spindle
  if (getProperty("gotSecondarySpindle")) {
    writeBlock(gSelectSpindleModal.format(getCode("SELECT_SPINDLE", getSection(0).spindle))); // cannot use getSpindle since there is not an active section
  }

  if (programComment) {
    writeln(formatComment(programComment));
  }

  if (getProperty("writeVersion")) {
    if ((typeof getHeaderVersion == "function") && getHeaderVersion()) {
      writeComment(localize("post version") + ": " + getHeaderVersion());
    }
    if ((typeof getHeaderDate == "function") && getHeaderDate()) {
      writeComment(localize("post modified") + ": " + getHeaderDate());
    }
  }

  // dump machine configuration
  var vendor = machineConfiguration.getVendor();
  var model = machineConfiguration.getModel();
  var mDescription = machineConfiguration.getDescription();

  if (getProperty("writeMachine") && (vendor || model || mDescription)) {
    writeComment(localize("Machine"));
    if (vendor) {
      writeComment("  " + localize("vendor") + ": " + vendor);
    }
    if (model) {
      writeComment("  " + localize("model") + ": " + model);
    }
    if (mDescription) {
      writeComment("  " + localize("description") + ": " + mDescription);
    }
  }

  // dump tool information
  if (getProperty("writeTools")) {
    var zRanges = {};
    if (is3D()) {
      var numberOfSections = getNumberOfSections();
      for (var i = 0; i < numberOfSections; ++i) {
        var section = getSection(i);
        var zRange = section.getGlobalZRange();
        var tool = section.getTool();
        if (zRanges[tool.number]) {
          zRanges[tool.number].expandToRange(zRange);
        } else {
          zRanges[tool.number] = zRange;
        }
      }
    }

    var tools = getToolTable();
    if (tools.getNumberOfTools() > 0) {
      for (var i = 0; i < tools.getNumberOfTools(); ++i) {
        var tool = tools.getTool(i);
        var comment = formatTool(tool, false) + " " +
          (tool.diameter != 0 ? "D=" + spatialFormat.format(tool.diameter) + " " : "") +
          (tool.isTurningTool() ? localize("NR") + "=" + spatialFormat.format(tool.noseRadius) : localize("CR") + "=" + spatialFormat.format(tool.cornerRadius)) +
          (tool.taperAngle > 0 && (tool.taperAngle < Math.PI) ? " " + localize("TAPER") + "=" + taperFormat.format(tool.taperAngle) + localize("deg") : "") +
          (zRanges[tool.number] ? " - " + localize("ZMIN") + "=" + spatialFormat.format(zRanges[tool.number].getMinimum()) : "") +
           " - " + localize(getToolTypeName(tool.type));
        writeComment(comment);
      }
    }
  }

  if (false) {
    // check for duplicate tool number
    for (var i = 0; i < getNumberOfSections(); ++i) {
      var sectioni = getSection(i);
      var tooli = sectioni.getTool();
      for (var j = i + 1; j < getNumberOfSections(); ++j) {
        var sectionj = getSection(j);
        var toolj = sectionj.getTool();
        if (tooli.number == toolj.number) {
          if (spatialFormat.areDifferent(tooli.diameter, toolj.diameter) ||
              spatialFormat.areDifferent(tooli.cornerRadius, toolj.cornerRadius) ||
              abcFormat.areDifferent(tooli.taperAngle, toolj.taperAngle) ||
              (tooli.numberOfFlutes != toolj.numberOfFlutes)) {
            error(
              subst(
                localize("Using the same tool number for different cutter geometry for operation '%1' and '%2'."),
                sectioni.hasParameter("operation-comment") ? sectioni.getParameter("operation-comment") : ("#" + (i + 1)),
                sectionj.hasParameter("operation-comment") ? sectionj.getParameter("operation-comment") : ("#" + (j + 1))
              )
            );
            return;
          }
        }
      }
    }
  }

  writeBlock(gAbsIncModal.format(90), gCycleModal.format(80));
  if (getProperty("useShortestDirection")) {
    writeBlock(mFormat.format(960));
  }

  onCommand(COMMAND_CLOSE_DOOR);

  if (getProperty("gotChipConveyor")) {
    onCommand(COMMAND_START_CHIP_TRANSPORT);
  }

  var mTool = getSection(0).getTool();
  var maximumSpindleSpeed = (mTool.maximumSpindleSpeed > 0) ? Math.min(mTool.maximumSpindleSpeed, getProperty("maximumSpindleSpeed")) : getProperty("maximumSpindleSpeed");
  if (maximumSpindleSpeed > 0) {
    writeBlock(gFormat.format(50), maxSpeedOutput.format(maximumSpindleSpeed));
    previousMaximumSpeed = maximumSpindleSpeed;
  }

  // automatically eject part at end of program
  if (getProperty("autoEject")) {
    ejectRoutine = true;
  }

  // CUSTOM: reset bar-pull tracking flags so a previous post run can't leak
  // state into this one (these are module-level so they persist).
  barPullPreludeEmitted = false;
  barPullWroteOwnWrapup = false;
  minMachinedZ = undefined;

  // CUSTOM: reset the gear-range and spindle-direction trackers used to
  // dedup M41/M42 and M03/M04 in startSpindle, so the very first section
  // of a fresh post always emits both. Also clear the machineState spindle
  // "active" flags that COMMAND_STOP_SPINDLE / startSpindle now read for
  // dedup, in case the engine keeps module state between post runs.
  lastEmittedGear = undefined;
  lastSpindleDirection = undefined;
  machineState.mainSpindleIsActive = false;
  machineState.subSpindleIsActive = false;
  machineState.liveToolIsActive = false;

  // CUSTOM: emit initial home retract so the program starts at the home position.
  // The redundant writeRetract(X, Z) inside onSection's "Position all axes at home"
  // block has been removed to avoid duplicating this on the first section.
  gMotionModal.reset();
  writeRetract(X);
  writeRetract(Z);
}

function onComment(message) {
  writeComment(message);
}

/** Force output of X, Y, and Z. */
function forceXYZ() {
  xOutput.reset();
  yOutput.reset();
  zOutput.reset();
}

/** Force output of A, B, and C. */
function forceABC() {
  aOutput.reset();
  bOutput.reset();
  cOutput.reset();
}

function forceFeed() {
  currentFeedId = undefined;
  feedOutput.reset();
}

/** Force output of X, Y, Z, A, B, C, and F on next output. */
function forceAny() {
  forceXYZ();
  forceABC();
  forceFeed();
}

function forceUnlockMultiAxis() {
  cAxisBrakeModal.reset();
}

function forceModals() {
  if (arguments.length == 0) { // reset all modal variables listed below
    if (typeof gMotionModal != "undefined") {
      gMotionModal.reset();
    }
    if (typeof gPlaneModal != "undefined") {
      gPlaneModal.reset();
    }
    if (typeof gAbsIncModal != "undefined") {
      gAbsIncModal.reset();
    }
    if (typeof gFeedModeModal != "undefined") {
      gFeedModeModal.reset();
    }
  } else {
    for (var i in arguments) {
      arguments[i].reset(); // only reset the modal variable passed to this function
    }
  }
}

function FeedContext(id, description, feed) {
  this.id = id;
  this.description = description;
  this.feed = feed;
}

// CUSTOM: return the feed mode we want to drive the section with. When
// 'feedPerRevForDrilling' is on and the section is a drilling cycle, force
// FEED_PER_REVOLUTION regardless of the Fusion operation's feedMode. The
// per-min -> per-rev conversion happens automatically in getFeed() because it
// keys off machineState.feedPerRevolution (set true when G95 is emitted) and
// the section's natural feedMode (still FEED_PER_MINUTE for in/min ops).
function getEffectiveFeedMode(section) {
  if (getProperty("feedPerRevForDrilling") &&
      section && isDrillingCycle(section, false)) {
    return FEED_PER_REVOLUTION;
  }
  return section.feedMode;
}

function formatFeedMode(mode) {
  var fMode = (mode == FEED_PER_REVOLUTION || tapping) ? getCode("FEED_MODE_UNIT_REV") : getCode("FEED_MODE_UNIT_MIN");
  if (fMode) {
    feedFormat = mode == FEED_PER_REVOLUTION ? fprFormat : fpmFormat;
    feedOutput.setFormat(feedFormat);
  }
  return gFeedModeModal.format(fMode);
}

function getFeed(f) {
  if (currentSection.feedMode != FEED_PER_REVOLUTION && machineState.feedPerRevolution) {
    f /= spindleSpeed;
  }
  if (activeMovements) {
    var feedContext = activeMovements[movement];
    if (feedContext != undefined) {
      if (!feedFormat.areDifferent(feedContext.feed, f)) {
        if (feedContext.id == currentFeedId) {
          return ""; // nothing has changed
        }
        forceFeed();
        currentFeedId = feedContext.id;
        return "F=V" + (firstFeedParameter + feedContext.id);
      }
    }
    currentFeedId = undefined; // force Q feed next time
  }
  return feedOutput.format(f); // use feed value
}

function initializeActiveFeeds() {
  activeMovements = new Array();
  var movements = currentSection.getMovements();
  var feedPerRev = currentSection.feedMode == FEED_PER_REVOLUTION;

  var id = 0;
  var activeFeeds = new Array();
  if (hasParameter("operation:tool_feedCutting")) {
    if (movements & ((1 << MOVEMENT_CUTTING) | (1 << MOVEMENT_LINK_TRANSITION) | (1 << MOVEMENT_EXTENDED))) {
      var feedContext = new FeedContext(id, localize("Cutting"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_CUTTING] = feedContext;
      if (!hasParameter("operation:tool_feedTransition")) {
        activeMovements[MOVEMENT_LINK_TRANSITION] = feedContext;
      }
      activeMovements[MOVEMENT_EXTENDED] = feedContext;
    }
    ++id;
    if (movements & (1 << MOVEMENT_PREDRILL)) {
      feedContext = new FeedContext(id, localize("Predrilling"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeMovements[MOVEMENT_PREDRILL] = feedContext;
      activeFeeds.push(feedContext);
    }
    ++id;
  }

  if (hasParameter("operation:finishFeedrate")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var finishFeedrateRel;
      if (hasParameter("operation:finishFeedrateRel")) {
        finishFeedrateRel = getParameter("operation:finishFeedrateRel");
      } else if (hasParameter("operation:finishFeedratePerRevolution")) {
        finishFeedrateRel = getParameter("operation:finishFeedratePerRevolution");
      }
      var feedContext = new FeedContext(id, localize("Finish"), feedPerRev ? finishFeedrateRel : getParameter("operation:finishFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var feedContext = new FeedContext(id, localize("Finish"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedEntry")) {
    if (movements & (1 << MOVEMENT_LEAD_IN)) {
      var feedContext = new FeedContext(id, localize("Entry"), feedPerRev ? getParameter("operation:tool_feedEntryRel") : getParameter("operation:tool_feedEntry"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_IN] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LEAD_OUT)) {
      var feedContext = new FeedContext(id, localize("Exit"), feedPerRev ? getParameter("operation:tool_feedExitRel") : getParameter("operation:tool_feedExit"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_OUT] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:noEngagementFeedrate")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(id, localize("Direct"), feedPerRev ? getParameter("operation:noEngagementFeedrateRel") : getParameter("operation:noEngagementFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting") &&
             hasParameter("operation:tool_feedEntry") &&
             hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(
        id,
        localize("Direct"),
        Math.max(
          feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"),
          feedPerRev ? getParameter("operation:tool_feedEntryRel") : getParameter("operation:tool_feedEntry"),
          feedPerRev ? getParameter("operation:tool_feedExitRel") : getParameter("operation:tool_feedExit")
        )
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:reducedFeedrate")) {
    if (movements & (1 << MOVEMENT_REDUCED)) {
      var feedContext = new FeedContext(id, localize("Reduced"), feedPerRev ? getParameter("operation:reducedFeedrateRel") : getParameter("operation:reducedFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_REDUCED] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedRamp")) {
    if (movements & ((1 << MOVEMENT_RAMP) | (1 << MOVEMENT_RAMP_HELIX) | (1 << MOVEMENT_RAMP_PROFILE) | (1 << MOVEMENT_RAMP_ZIG_ZAG))) {
      var feedContext = new FeedContext(id, localize("Ramping"), feedPerRev ? getParameter("operation:tool_feedRampRel") : getParameter("operation:tool_feedRamp"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_RAMP] = feedContext;
      activeMovements[MOVEMENT_RAMP_HELIX] = feedContext;
      activeMovements[MOVEMENT_RAMP_PROFILE] = feedContext;
      activeMovements[MOVEMENT_RAMP_ZIG_ZAG] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:tool_feedPlunge")) {
    if (movements & (1 << MOVEMENT_PLUNGE)) {
      var feedContext = new FeedContext(id, localize("Plunge"), feedPerRev ? getParameter("operation:tool_feedPlungeRel") : getParameter("operation:tool_feedPlunge"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_PLUNGE] = feedContext;
    }
    ++id;
  }
  if (true) { // high feed
    if ((movements & (1 << MOVEMENT_HIGH_FEED)) || (highFeedMapping != HIGH_FEED_NO_MAPPING)) {
      var feed;
      if (hasParameter("operation:highFeedrateMode") && getParameter("operation:highFeedrateMode") != "disabled") {
        feed = getParameter("operation:highFeedrate");
      } else {
        feed = this.highFeedrate;
      }
      var feedContext = new FeedContext(id, localize("High Feed"), feed);
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_HIGH_FEED] = feedContext;
      activeMovements[MOVEMENT_RAPID] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:tool_feedTransition")) {
    if (movements & (1 << MOVEMENT_LINK_TRANSITION)) {
      var feedContext = new FeedContext(id, localize("Transition"), getParameter("operation:tool_feedTransition"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_TRANSITION] = feedContext;
    }
    ++id;
  }

  for (var i = 0; i < activeFeeds.length; ++i) {
    var feedContext = activeFeeds[i];
    writeBlock("V" + (firstFeedParameter + feedContext.id) + "=" + feedFormat.format(feedContext.feed), formatComment(feedContext.description));
  }
}

var currentWorkPlaneABC = undefined;

function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
}

function setWorkPlane(abc) {
  // milling only

  if (!machineConfiguration.isMultiAxisConfiguration()) {
    return; // ignore
  }

  if (!((currentWorkPlaneABC == undefined) ||
        abcFormat.areDifferent(abc.x, currentWorkPlaneABC.x) ||
        abcFormat.areDifferent(abc.y, currentWorkPlaneABC.y) ||
        abcFormat.areDifferent(abc.z, currentWorkPlaneABC.z))) {
    return; // no change
  }

  onCommand(COMMAND_UNLOCK_MULTI_AXIS);

  writeBlock(
    gMotionModal.format(0),
    conditional(machineConfiguration.isMachineCoordinate(0), aOutput.format(abc.x)),
    conditional(machineConfiguration.isMachineCoordinate(1), bFormat.format(abc.y)),
    conditional(machineConfiguration.isMachineCoordinate(2), cOutput.format(abc.z))
  );

  onCommand(COMMAND_LOCK_MULTI_AXIS);

  currentWorkPlaneABC = new Vector(abc);
  setCurrentDirection(abc);
}

function getBestABC(section) {
  // try workplane orientation
  var abc = section.getABCByPreference(machineConfiguration, section.workPlane, getCurrentDirection(), C, PREFER_CLOSEST, ENABLE_ALL);
  if (section.doesToolpathFitWithinLimits(machineConfiguration, abc)) {
    return abc;
  }
  var currentABC = new Vector(abc);

  // quadrant boundaries are the preferred solution
  var quadrants = [0, 90, 180, 270];
  for (var i = 0; i < quadrants.length; ++i) {
    abc.setZ(toRad(quadrants[i]));
    if (section.doesToolpathFitWithinLimits(machineConfiguration, abc)) {
      abc = machineConfiguration.remapToABC(abc, currentABC);
      abc = machineConfiguration.remapABC(abc);
      return abc;
    }
  }

  // attempt to find soultion at fixed angle rotations
  var maxTries = 60; // every 6 degrees
  var delta = (Math.PI * 2) / maxTries;
  var angle = delta;
  for (var i = 0; i < (maxTries - 1); i++) {
    abc.setZ(angle);
    if (section.doesToolpathFitWithinLimits(machineConfiguration, abc)) {
      abc = machineConfiguration.remapToABC(abc, currentABC);
      abc = machineConfiguration.remapABC(abc);
      return abc;
    }
    angle += delta;
  }
  return abc;
}

function getWorkPlaneMachineABC(section, workPlane) {
  var W = workPlane; // map to global frame

  var abc;
  if (machineState.isTurningOperation && gotBAxis) {
    var both = machineConfiguration.getABCByDirectionBoth(workPlane.forward);
    abc = both[0];
    if (both[0].z != 0) {
      abc = both[1];
    }
  } else {
    abc = bestABC ? bestABC :
      section.getABCByPreference(machineConfiguration, W, getCurrentDirection(), C, PREFER_CLOSEST, ENABLE_RESET);
  }

  var direction = machineConfiguration.getDirection(abc);
  if (!isSameDirection(direction, W.forward)) {
    error(localize("Orientation not supported."));
  }

  if (machineState.isTurningOperation && gotBAxis && !bAxisIsManual) { // remapABC can change the B-axis orientation
    if (abc.z != 0) {
      error(localize("Could not calculate a B-axis turning angle within the range of the machine."));
    }
  }

  var tcp = false;
  if (tcp) {
    setRotation(W); // TCP mode
  } else {
    var O = machineConfiguration.getOrientation(abc);
    var R = machineConfiguration.getRemainingOrientation(abc, W);
    setRotation(R);
  }

  if (machineState.usePolarCoordinates) { // set C-axis to initial polar coordinate position
    var initialPosition = getFramePosition(section.getInitialPosition());
    var polarPosition = getPolarCoordinates(initialPosition, abc);
    abc.setZ(polarPosition.second.z);
  }
  return abc;
}

var bAxisOrientationTurning = new Vector(0, 0, 0);

function setSpindleOrientationTurning() {
  var J; // cutter orientation
  var R; // cutting quadrant
  var leftHandTool = (hasParameter("operation:tool_hand") && (getParameter("operation:tool_hand") == "L" || getParameter("operation:tool_holderType") == 0));
  if (hasParameter("operation:machineInside")) {
    if (getParameter("operation:machineInside") == 0) {
      R = (currentSection.spindle == SPINDLE_PRIMARY) ? 3 : 4;
    } else {
      R = (currentSection.spindle == SPINDLE_PRIMARY) ? 2 : 1;
    }
  } else {
    if ((hasParameter("operation-strategy") && getParameter("operation-strategy") == "turningFace") ||
      (hasParameter("operation-strategy") && getParameter("operation-strategy") == "turningPart")) {
      R = (currentSection.spindle == SPINDLE_PRIMARY) ? 3 : 4;
    } else {
      error(subst(localize("Failed to identify spindle orientation for operation \"%1\"."), getOperationComment()));
      return;
    }
  }
  if (leftHandTool) {
    J = (currentSection.spindle == SPINDLE_PRIMARY) ? 2 : 1;
  } else {
    J = (currentSection.spindle == SPINDLE_PRIMARY) ? 1 : 2;
  }
  writeComment("Post processor is not customized, add code for cutter orientation and cutting quadrant here if needed.");
}

var bAxisOrientationTurning = new Vector(0, 0, 0);

function getBAxisOrientationTurning(section) {
  // THIS CODE IS NOT TESTED.
  var toolAngle = hasParameter("operation:tool_angle") ? getParameter("operation:tool_angle") : 0;
  var toolOrientation = section.toolOrientation;
  if (toolAngle && toolOrientation != 0) {
    // error(localize("You cannot use tool angle and tool orientation together in operation " + "\"" + (getParameter("operation-comment")) + "\""));
  }

  var angle = toRad(toolAngle) + toolOrientation;

  var axis = new Vector(0, 1, 0);
  var mappedAngle;
  if (bAxisIsManual) {
    mappedAngle = 0; // manual b-axis used for milling only
  } else {
    mappedAngle = (currentSection.spindle == SPINDLE_PRIMARY ? (Math.PI / 2 - angle) : (Math.PI / 2 - angle));
  }
  var mappedWorkplane = new Matrix(axis, mappedAngle);
  var abc = getWorkPlaneMachineABC(section, mappedWorkplane);
  return abc;
}

function getSpindle(whichSpindle) {
  // safety conditions
  if (getNumberOfSections() == 0) {
    return SPINDLE_MAIN;
  }
  if (getCurrentSectionId() < 0) {
    if (machineState.liveToolIsActive && (whichSpindle == TOOL)) {
      return SPINDLE_LIVE;
    } else {
      return getSection(getNumberOfSections() - 1).spindle;
    }
  }

  // Turning is active or calling routine requested which spindle part is loaded into
  if (machineState.isTurningOperation || machineState.axialCenterDrilling || (whichSpindle == PART)) {
    return currentSection.spindle;
  //Milling is active
  } else {
    return SPINDLE_LIVE;
  }
}

function getSecondarySpindle() {
  var spindle = getSpindle(PART);
  return (spindle == SPINDLE_MAIN) ? SPINDLE_SUB : SPINDLE_MAIN;
}

function isPerpto(a, b) {
  return Math.abs(Vector.dot(a, b)) < (1e-7);
}

function onSectionSpecialCycle() {
  if (!isFirstSection()) {
    activateMachine(currentSection);
  }
}

function onSection() {

  // Detect machine configuration
  var currentTurret = isFirstSection() ? activeTurret : activateMachine(currentSection);

  // Define Machining modes
  tapping = isTappingCycle();

  var forceSectionRestart = optionalSection && !currentSection.isOptional();
  optionalSection = currentSection.isOptional();
  bestABC = undefined;
  setCurrentDirection(isFirstSection() ? new Vector(0, 0, 0) : getCurrentDirection());

  machineState.isTurningOperation = (currentSection.getType() == TYPE_TURNING);
  if (machineState.isTurningOperation && gotBAxis) {
    bAxisOrientationTurning = getBAxisOrientationTurning(currentSection);
  }
  var insertToolCall = isToolChangeNeeded("number", "compensationOffset", "diameterOffset", "lengthOffset") || forceSectionRestart;
  var newWorkOffset = isNewWorkOffset() || forceSectionRestart;
  var newWorkPlane = isNewWorkPlane() || forceSectionRestart ||
    (machineState.isTurningOperation &&
      abcFormat.areDifferent(bAxisOrientationTurning.x, machineState.currentBAxisOrientationTurning.x) ||
      abcFormat.areDifferent(bAxisOrientationTurning.y, machineState.currentBAxisOrientationTurning.y) ||
      abcFormat.areDifferent(bAxisOrientationTurning.z, machineState.currentBAxisOrientationTurning.z));
  var retracted = false; // specifies that the tool has been retracted to the safe plane

  partCutoff = getParameter("operation-strategy", "") == "turningPart";
  operationNeedsSafeStart = getProperty("safeStartAllOperations") && !isFirstSection();

  var yAxisWasEnabled = !machineState.usePolarCoordinates && !machineState.usePolarInterpolation && machineState.liveToolIsActive;
  updateMachiningMode(currentSection); // sets the needed machining mode to machineState (usePolarInterpolation, usePolarCoordinates, axialCenterDrilling)

  // Get the active spindle
  var newSpindle = true;
  var tempSpindle = getSpindle(TOOL);
  if (isFirstSection()) {
    previousSpindle = tempSpindle;
  }
  newSpindle = tempSpindle != previousSpindle;

  // End the previous section if a new tool is selected.
  // CUSTOM: if the previous section was a tool-based bar pull, it already
  // emitted its own wrap-up (retract X, retract Z, optional stop) at the end
  // of writeToolBarPullerCycle. Skip this block so we don't double up the
  // home retract / M01. Consume the flag here so a later same-tool section
  // (no insertToolCall) doesn't accidentally swallow a future wrap-up.
  if (barPullWroteOwnWrapup) {
    barPullWroteOwnWrapup = false;
  } else if (!isFirstSection() && insertToolCall &&
      !(machineState.stockTransferIsActive && partCutoff)) {
    if (machineState.stockTransferIsActive) {
      writeBlock(mFormat.format(getCode("SPINDLE_SYNCHRONIZATION_OFF", getSpindle(PART))), formatComment("SYNCHRONIZED ROTATION OFF"));
    } else {
      if (previousSpindle == SPINDLE_LIVE) {
        onCommand(COMMAND_STOP_SPINDLE);
        forceUnlockMultiAxis();
        if (tempSpindle != SPINDLE_LIVE) {
          writeTurningModeEntry(); // CUSTOM: configurable G270 / M109 / none
        } else {
          onCommand(COMMAND_UNLOCK_MULTI_AXIS);
          if ((tempSpindle != SPINDLE_LIVE) && !getProperty("optimizeCAxisSelect")) {
            cAxisEngageModal.reset();
            writeBlock(cAxisEngageModal.format(getCode("DISABLE_C_AXIS", getSpindle(PART))));
          }
        }
      } else {
        // CUSTOM: stop the main spindle too so the M05 lands inside the
        // previous section's wrap-up (before the retract + M01) instead of at
        // the top of the next section. COMMAND_STOP_SPINDLE in onCommand is
        // dedup-suppressed when the spindle isn't actually running, so this
        // is a safe no-op when there's nothing to stop.
        onCommand(COMMAND_STOP_SPINDLE);
      }
      onCommand(COMMAND_COOLANT_OFF);
    }
    writeRetract(X);
    writeRetract(Z);

    // cancel tool length compensation
    if (!isFirstSection() && insertToolCall && !(currentSection.getType() == TYPE_TURNING)) {
      // writeBlock(formatTool(getPreviousSection().getTool(), true)); // may cause collision
    }

    // cancel load monitoring
    if (!isFirstSection() && insertToolCall && (getProperty("loadMonitoring") != 0)) {
      writeln("VLMON[" + vlmon + "]=0");
      writeln(mFormat.format(215));
    }

    if (getProperty("optionalStop")) {
      onCommand(COMMAND_OPTIONAL_STOP);
      gMotionModal.reset();
    }
  }
  // Consider part cutoff as stockTransfer operation
  if (!(machineState.stockTransferIsActive && partCutoff)) {
    machineState.stockTransferIsActive = false;
  }

  // Output the operation description
  writeln("");
  if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      if (!insertToolCall && getProperty("showSequenceNumbers") == "toolChange") {
        writeCommentSeqno(comment);
      } else {
        writeComment(comment);
      }
    }
  }

  // Select the active spindle
  if (getProperty("gotSecondarySpindle")) {
    writeBlock(gSelectSpindleModal.format(getCode("SELECT_SPINDLE", getSpindle(PART))));
  }

  // activate Y-axis
  if (gotYAxis && (getSpindle(TOOL) == SPINDLE_LIVE) && !machineState.usePolarInterpolation && !machineState.usePolarCoordinates) {
    writeBlock(gPolarModal.format(getCode("ENABLE_Y_AXIS", true)));
    yOutput.enable();
  }

  // Position all axes at home
  if (insertToolCall && !machineState.stockTransferIsActive || operationNeedsSafeStart) {
    var isRequired = insertToolCall && !machineState.stockTransferIsActive;
    writeStartBlocks(isRequired, function() {
      /*
        if (getProperty("gotSecondarySpindle")) {
          writeBlock(gMotionModal.format(0), gFormat.format(28), gFormat.format(53), "B" + abcFormat.format(0)); // retract Sub Spindle if applicable
        }
    */
      // CUSTOM: redundant writeRetract(X, Z) removed -- onOpen emits the initial
      // home, and the previous section's wrap-up (above) already retracted.
      gMotionModal.reset();

      // Stop the spindle
      if (newSpindle) {
        onCommand(COMMAND_STOP_SPINDLE);
      }
    });
  }

  var wcsOut = "";
  // wcs
  /*
  if (insertToolCall) { // force work offset when changing tool
    currentWorkOffset = undefined;
  }

  if (currentSection.workOffset != currentWorkOffset) {
    forceWorkPlane();
    wcsOut = currentSection.wcs;
    currentWorkOffset = currentSection.workOffset;
  }
 */

  // Get active feedrate mode
  if (insertToolCall) {
    forceModals();
  }
  // CUSTOM: optionally force feed-per-rev (G95) for drilling sections
  var feedMode = formatFeedMode(getEffectiveFeedMode(currentSection));

  // calculate rotary angles
  var abc = new Vector(0, 0, 0);
  if (machineConfiguration.isMultiAxisConfiguration()) {
    if (machineState.isTurningOperation) {
      if (gotBAxis && (currentTurret != 2)) {
        cancelTransformation();
        // handle B-axis support for turning operations here
        abc = bAxisOrientationTurning;
      } else {
        abc = getWorkPlaneMachineABC(currentSection, currentSection.workPlane);
      }
    } else {
      if (currentSection.isMultiAxis() || isPolarModeActive()) {
        forceWorkPlane();
        cancelTransformation();
        // onCommand(COMMAND_UNLOCK_MULTI_AXIS);
        abc = currentSection.isMultiAxis() ? currentSection.getInitialToolAxisABC() : getCurrentDirection();
      } else {
        abc = getWorkPlaneMachineABC(currentSection, currentSection.workPlane);
      }
    }
  } else { // pure 3D
    var remaining = currentSection.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
      error(localize("Tool orientation is not supported by the CNC machine."));
      return;
    }
    setRotation(remaining);
  }

  // Live Spindle is active
  if (tempSpindle == SPINDLE_LIVE) {
    if (insertToolCall || wcsOut || feedMode || operationNeedsSafeStart) {
      var isRequired = insertToolCall || wcsOut || feedMode;
      writeStartBlocks(isRequired, function() {
        forceUnlockMultiAxis();
        onCommand(COMMAND_UNLOCK_MULTI_AXIS);
        var plane;
        switch (machineState.machiningDirection) {
        case MACHINING_DIRECTION_AXIAL:
          plane = getG17Code();
          break;
        case MACHINING_DIRECTION_RADIAL:
          plane = 19;
          break;
        case MACHINING_DIRECTION_INDEXING:
          plane = getG17Code();
          break;
        default:
          error(subst(localize("Unsupported machining direction for operation " + "\"" + "%1" + "\"" + "."), getOperationComment()));
          return;
        }
        gPlaneModal.reset();
        if (!getProperty("optimizeCAxisSelect")) {
          cAxisEngageModal.reset();
        }
        // writeBlock(wcsOut, mFormat.format(getCode("SET_SPINDLE_FRAME", getSpindle(PART))));
        writeBlock(feedMode, gPlaneModal.format(plane), cAxisEngageModal.format(getCode("ENABLE_C_AXIS", getSpindle(PART))));
        //writeBlock(gMotionModal.format(0), gFormat.format(28), "H" + abcFormat.format(0)); // unwind c-axis
        if (!machineState.usePolarInterpolation && !machineState.usePolarCoordinates && !currentSection.isMultiAxis()) {
          onCommand(COMMAND_LOCK_MULTI_AXIS);
        }
      });
    }

  // Turning is active
  } else {
    if ((insertToolCall || wcsOut || feedMode) && !machineState.stockTransferIsActive) {
      // forceUnlockMultiAxis();
      // writeBlock(cAxisEngageModal.format(getCode("UNLOCK_MULTI_AXIS", getSpindle(PART))));
      gPlaneModal.reset();
      if (!getProperty("optimizeCAxisSelect")) {
        cAxisEngageModal.reset();
      }
      // writeBlock(wcsOut, mFormat.format(getSpindle(PART) == SPINDLE_SUB ? 83 : 80));
      writeTurningModeEntry(); // CUSTOM: configurable G270 / M109 / none
      writeBlock(feedMode, gPlaneModal.format(18));
    } else {
      writeBlock(feedMode);
    }
  }

  // Write out maximum spindle speed
  var maximumSpindleSpeed = (tool.maximumSpindleSpeed > 0) ? Math.min(tool.maximumSpindleSpeed, getProperty("maximumSpindleSpeed")) : getProperty("maximumSpindleSpeed");
  if ((maximumSpindleSpeed > 0) && (currentSection.getTool().getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED)) {
    if ((/*insertToolCall || */rpmFormat.areDifferent(maximumSpindleSpeed, previousMaximumSpeed)) && !machineState.stockTransferIsActive) {
      writeBlock(gFormat.format(50), maxSpeedOutput.format(maximumSpindleSpeed));
      previousMaximumSpeed = maximumSpindleSpeed;
    }
  } else {
    //previousMaximumSpeed = 0; // reset for RPM spindle speeds
  }

  // Write out notes
  if (getProperty("showNotes") && hasParameter("notes")) {
    var notes = getParameter("notes");
    if (notes) {
      var lines = String(notes).split("\n");
      var r1 = new RegExp("^[\\s]+", "g");
      var r2 = new RegExp("[\\s]+$", "g");
      for (line in lines) {
        var comment = lines[line].replace(r1, "").replace(r2, "");
        if (comment) {
          writeComment(comment);
        }
      }
    }
  }

  if (insertToolCall || operationNeedsSafeStart) {
    writeStartBlocks(insertToolCall, function () {
      forceWorkPlane();
      cAxisEngageModal.reset();
      retracted = insertToolCall;
      onCommand(COMMAND_COOLANT_OFF);

      if (tool.compensationOffset > getProperty("maxToolOffset")) {
        error(localize("Compensation offset is out of range."));
        return;
      }
      if (tool.lengthOffset > getProperty("maxToolOffset")) {
        error(localize("Compensation offset is out of range."));
        return;
      }
      if (tool.number > getProperty("maxTool")) {
        warning(localize("Tool number exceeds maximum value."));
      }

      if (tool.number == 0) {
        error(localize("Tool number cannot be 0"));
        return;
      }

      gMotionModal.reset();
      if (getProperty("showSequenceNumbers") == "toolChange") {
        showSequenceNumbers = "true";
      }

      writeBlock(formatTool(tool, false));
      if (tool.comment) {
        writeComment(tool.comment);
      }

      // Turn on coolant
      setCoolant(tool.coolant);

      // enable load monitoring
      if (getProperty("loadMonitoring") != 0) {
        vlmon = tool.number;
        writeln("VLMON[" + vlmon + "]=" + getProperty("loadMonitoring"));
        writeln(mFormat.format(216));
      }
    });
  }

  // Activate part catcher for part cutoff section
  if (getProperty("usePartCatcher") && partCutoff && currentSection.partCatcher) {
    engagePartCatcher(true);
  }

  // command stop for manual tool change, useful for quick change live tools
  if (insertToolCall && tool.manualToolChange) {
    onCommand(COMMAND_STOP);
    writeComment("MANUAL TOOL CHANGE TO " + formatTool(tool, false));
  }

  // Engage tailstock
  if (getProperty("useTailStock")) {
    if (machineState.axialCenterDrilling || (getSpindle(PART) == SPINDLE_SUB) ||
       ((getSpindle(TOOL) == SPINDLE_LIVE) && (machineState.machiningDirection == MACHINING_DIRECTION_AXIAL))) {
      if (currentSection.tailstock) {
        warning(localize("Tail stock is not supported for secondary spindle or Z-axis milling."));
      }
      if (machineState.tailstockIsActive) {
        writeBlock(tailStockModal.format(getCode("TAILSTOCK_OFF", SPINDLE_MAIN)));
      }
    } else {
      writeBlock(tailStockModal.format(currentSection.tailstock ? getCode("TAILSTOCK_ON", SPINDLE_MAIN) : getCode("TAILSTOCK_OFF", SPINDLE_MAIN)));
    }
  }

  // Output spindle codes
  if (newSpindle) {
    // select spindle if required
  }

  var forceRPMMode = false;
  var spindleChanged = tool.type != TOOL_PROBE && !machineState.stockTransferIsActive &&
    (insertToolCall || forceSpindleSpeed || isSpindleSpeedDifferent() || newSpindle);
  if (spindleChanged || operationNeedsSafeStart) {
    forceSpindleSpeed = false;
    if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
      if (spindleSpeed > maximumSpindleSpeed) {
        warning(subst(localize("Spindle speed exceeds maximum value for operation \"%1\"."), getOperationComment()));
      }
    } else {
      if (spindleSpeed > 6000) {
        warning(subst(localize("Spindle speed exceeds maximum value for operation \"%1\"."), getOperationComment()));
      }
    }

    // Turn spindle on
    forceRPMMode = tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED;
    writeStartBlocks(spindleChanged, function () {
      startSpindle(false, true, getFramePosition(currentSection.getInitialPosition()));
    });
  }

  forceAny();
  gMotionModal.reset();

  if (currentSection.isMultiAxis()) {
    writeBlock(gMotionModal.format(0), aOutput.format(abc.x), bOutput.format(abc.y), cOutput.format(abc.z));
    forceWorkPlane();
    cancelTransformation();
  } else {
    if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
      if (gotBAxis) {
        bOutput.reset();
        writeBlock(gMotionModal.format(0), bOutput.format(getB(abc, currentSection)));
        machineState.currentBAxisOrientationTurning = abc;
      }
    } else if (!machineState.usePolarCoordinates && !machineState.usePolarInterpolation) {
      setWorkPlane(abc);
    }
  }

  // enable Polar coordinates mode
  if (machineState.usePolarCoordinates && (tool.type != TOOL_PROBE)) {
    if (polarCoordinatesDirection == undefined) {
      error(localize("Polar coordinates axis direction to maintain must be defined as a vector - x,y,z."));
      return;
    }
    setPolarCoordinates(true);
  }

  forceAny();

  gMotionModal.reset();
  var initialPosition = getFramePosition(currentSection.getInitialPosition());

  if (insertToolCall || retracted || (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) || operationNeedsSafeStart) {
    var isRequired = insertToolCall || retracted || (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED);
    writeStartBlocks(isRequired, function() {
      // gPlaneModal.reset();
      gMotionModal.reset();
      if (machineState.usePolarCoordinates) {
        var polarPosition = getPolarCoordinates(initialPosition, abc);
        setCAxisDirection(cOutput.getCurrent(), polarPosition.second.z);
        writeBlock(gMotionModal.format(0), zOutput.format(polarPosition.first.z));
        writeBlock(
          gMotionModal.format(0),
          xOutput.format(polarPosition.first.x),
          gotYAxis ? yOutput.format(0) : "",
          cOutput.format(polarPosition.second.z)
        );
      } else if (machineState.usePolarInterpolation) {
        var polarPosition = getPolarCoordinates(initialPosition, abc);
        writeBlock(gMotionModal.format(0), zOutput.format(polarPosition.first.z));
        writeBlock(
          gMotionModal.format(0),
          xOutput.format(polarPosition.first.x),
          gotYAxis ? yOutput.format(0) : ""
        );
      } else {
        writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
        writeBlock(gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(0));
      }
    });
  } else if ((machineState.usePolarCoordinates || machineState.usePolarInterpolation) && yAxisWasEnabled) {
    if (gotYAxis && yOutput.isEnabled()) {
      writeBlock(gMotionModal.format(0), yOutput.format(0));
    }
  }
  if (operationNeedsSafeStart) {
    forceXYZ();
  }

  // enable SFM spindle speed
  if (forceRPMMode) {
    startSpindle(false, false);
  }

  if (machineState.usePolarInterpolation) {
    setPolarInterpolation(true); // enable polar interpolation mode
  }

  if (getProperty("useParametricFeed") && !isDrillingCycle(true)) {
    if (!insertToolCall &&
        activeMovements &&
        (getCurrentSectionId() > 0) &&
        ((getPreviousSection().getPatternId() == currentSection.getPatternId()) && (currentSection.getPatternId() != 0))) {
      // use the current feeds
    } else {
      initializeActiveFeeds();
    }
  } else {
    activeMovements = undefined;
  }

  previousSpindle = tempSpindle;
  activeSpindle = tempSpindle;

  if (false) { // DEBUG
    for (var key in machineState) {
      writeComment(key + " : " + machineState[key]);
    }
    writeComment("Tapping = " + tapping);
    // writeln("(" + (getMachineConfigurationAsText(machineConfiguration)) + ")");
  }
}

var MACHINING_DIRECTION_AXIAL = 0;
var MACHINING_DIRECTION_RADIAL = 1;
var MACHINING_DIRECTION_INDEXING = 2;

function getMachiningDirection(section) {
  var forward = section.workPlane.forward;
  if (section.isMultiAxis()) {
    forward = section.getGlobalInitialToolAxis();
    forward = Math.abs(forward.z) < 1e-7 ? new Vector(1, 0, 0) : forward; // radial multi-axis operation
  }
  if (isSameDirection(forward, new Vector(0, 0, 1))) {
    return MACHINING_DIRECTION_AXIAL;
  } else if (Vector.dot(forward, new Vector(0, 0, 1)) < 1e-7) {
    return MACHINING_DIRECTION_RADIAL;
  } else {
    return MACHINING_DIRECTION_INDEXING;
  }
}

/** Helper function to determine the polar machining options set in the user interface */
var IN_CONTROL = 0;
var IN_COMPUTER = 1;
function getOperationPolarMode(section) {
  var mode = undefined;
  if (revision >= 50294) {
    if (section.getParameter("operation:usePolarWhenNecessary", 0) == 1) {
      if (section.getParameter("operation:polarMode", false) == "computer") {
        mode = IN_COMPUTER;
      } else if (section.getParameter("operation:polarMode", false) == "control") {
        mode = IN_CONTROL;
      }
    } else if (section.polarMode && section.polarMode != POLAR_MODE_OFF) {
      if (section.getParameter("operation:polarMode", false) == "computer") {
        mode = IN_COMPUTER;
      } else if (section.getParameter("operation:polarMode", false) == "control") {
        mode = IN_CONTROL;
      } else { // automatic mode
        if (Vector.diff(defaultPolarCoordinatesDirection, section.polarDirection).length > 1e-4) {
          mode = IN_COMPUTER; // force polar coordinates when polarDirection is non zero in automatic mode
        } else {
          mode = gotPolarInterpolation ? IN_CONTROL : IN_COMPUTER; // use polar interpolation if available, otherwise polar coordinates
        }
      }
    }
  }
  return mode;
}

function updateMachiningMode(section) {
  machineState.axialCenterDrilling = false; // reset
  machineState.usePolarInterpolation = false; // reset
  machineState.usePolarCoordinates = false; // reset

  machineState.machiningDirection = getMachiningDirection(section);
  var operationPolarMode = getOperationPolarMode(section); // determine the polar machining options set in the user interface
  if (operationPolarMode != undefined && (forcePolarCoordinates || forcePolarInterpolation)) {
    error("The Manual NC \"Action\" command to enable polar machining and the operation option \"Machining Type Polar\" cannot be used together." + EOL +
      "Please select only one option to enable polar machining.");
  }

  if ((section.getType() == TYPE_MILLING) && !section.isMultiAxis()) {
    if (machineState.machiningDirection == MACHINING_DIRECTION_AXIAL) {
      if (isDrillingCycle(section, false)) {
        // drilling axial
        machineState.axialCenterDrilling = isAxialCenterDrilling(section, true);
        if (!machineState.axialCenterDrilling && !isAxialCenterDrilling(section, false)) { // several holes not on XY center
          if (operationPolarMode != undefined) {
            if (operationPolarMode == IN_CONTROL) {
              warning(subst(localize("Polar mode \"In Control\" is not supported for drilling operation \"%1\". The post processor will use mode \"Automatic\" instead."), getOperationComment()));
            } else if (operationPolarMode == IN_COMPUTER) {
              machineState.usePolarCoordinates = true;
              polarCoordinatesDirection = section.polarDirection;
              if (getProperty("useYAxisForDrilling")) {
                warning(subst(localize("Polar mode was requested for operation \"%1\". Therefore, the post property \"" + properties.useYAxisForDrilling.title + "\" will be ignored."), getOperationComment()));
              }
            }
          } else {
          // bestABC = section.getABCByPreference(machineConfiguration, section.workPlane, getCurrentDirection(), C, PREFER_CLOSEST, ENABLE_RESET | ENABLE_LIMITS);
            bestABC = getBestABC(section);
            bestABC = section.doesToolpathFitWithinLimits(machineConfiguration, bestABC) ? bestABC : undefined;
            if (!getProperty("useYAxisForDrilling") || bestABC == undefined) {
              machineState.usePolarCoordinates = true;
            }
          }
        }
      } else { // milling
        // Use new operation property for polar milling if available
        if (operationPolarMode != undefined) {
          forcePolarCoordinates = operationPolarMode == IN_COMPUTER;
          forcePolarInterpolation = operationPolarMode == IN_CONTROL;
          polarCoordinatesDirection = section.polarDirection;
        }
        if (gotPolarInterpolation && forcePolarInterpolation) { // polar mode is requested by user
          machineState.usePolarInterpolation = true;
          bestABC = undefined;
        } else if (forcePolarCoordinates) { // Polar coordinate mode is requested by user
          machineState.usePolarCoordinates = true;
          bestABC = undefined;
        } else {
          //bestABC = section.getABCByPreference(machineConfiguration, section.workPlane, getCurrentDirection(), C, PREFER_CLOSEST, ENABLE_RESET | ENABLE_LIMITS);
          bestABC = getBestABC(section);
          bestABC = section.doesToolpathFitWithinLimits(machineConfiguration, bestABC) ? bestABC : undefined;
          if (bestABC == undefined) { // toolpath does not match XY ranges, enable interpolation mode
            if (gotPolarInterpolation) {
              machineState.usePolarInterpolation = true;
            } else {
              machineState.usePolarCoordinates = true;
            }
          }
        }
      }
    } else if (machineState.machiningDirection == MACHINING_DIRECTION_RADIAL) { // G19 plane
      var range = section.getOptimizedBoundingBox(machineConfiguration, machineConfiguration.getABC(section.workPlane));
      var yAxisWithinLimits = machineConfiguration.getAxisY().getRange().isWithin(yFormat.getResultingValue(range.lower.y)) &&
        machineConfiguration.getAxisY().getRange().isWithin(yFormat.getResultingValue(range.upper.y));
      if (!gotYAxis) {
        if (!section.isMultiAxis() && !yAxisWithinLimits) {
          error(subst(localize("Y-axis motion is not possible without a Y-axis for operation \"%1\"."), getOperationComment()));
          return;
        }
      } else {
        if (!yAxisWithinLimits) {
          error(subst(localize("Toolpath exceeds the maximum ranges for operation \"%1\"."), getOperationComment()));
          return;
        }
      }
      // C-coordinates come from setWorkPlane or is within a multi axis operation, we cannot use the C-axis for non wrapped toolpathes (only multiaxis works, all others have to be into XY range)
    } else {
      // usePolarCoordinates & usePolarInterpolation is only supported for axial machining, keep false
    }
  } else {
    // turning or multi axis, keep false
  }

  if (machineState.axialCenterDrilling) {
    cOutput.disable();
  } else {
    cOutput.enable();
  }

  // validations
  if (forcePolarInterpolation && !gotPolarInterpolation) {
    warning(localize("Polar mode \"In Control\" has been requested but is either disabled or not supported by the machine." + EOL +
      "The post processor will use mode \"Automatic\" instead."));
  }
  if (machineState.usePolarCoordinates && section.getParameter("operation:compensationType", false) == "control") {
    error(subst(localize("Polar interpolation type \"In Control\" is required for using cutter compensation type \"In Control\" in operation \"%1\", but is either disabled or unsupported by the machine."), getOperationComment()));
  }
  var checksum = 0;
  checksum += machineState.usePolarInterpolation ? 1 : 0;
  checksum += machineState.usePolarCoordinates ? 1 : 0;
  checksum += machineState.axialCenterDrilling ? 1 : 0;
  validate(checksum <= 1, localize("Internal post processor error."));
}

function getOperationComment() {
  var operationComment = hasParameter("operation-comment") && getParameter("operation-comment");
  return operationComment;
}

function setRadiusDiameterMode(mode) {
  if (mode == "diameter") {
    xFormat.setScale(2);
  } else {
    xFormat.setScale(1);
  }
  xOutput.setFormat(xFormat);
}

function setPolarInterpolation(activate) {
  if (activate) {
    setCAxisDirection(cOutput.getCurrent(), 0);
    cOutput.enable();
    cOutput.reset();
    writeBlock(gPolarModal.format(getCode("POLAR_INTERPOLATION_ON", getSpindle(PART))), cOutput.format(0)); // command for polar interpolation
    writeBlock(gPlaneModal.format(getG17Code()));
    yOutput.setPrefix("Y");
    yOutput.enable(); // required for G12.1
    cOutput.disable();
    setRadiusDiameterMode("radius");
  } else {
    writeBlock(gPolarModal.format(getCode("POLAR_INTERPOLATION_OFF", getSpindle(PART))));
    yOutput.setPrefix("Y");
    yOutput.disable();
    cOutput.enable();
    setRadiusDiameterMode("diameter");
    if (currentWorkPlaneABC != undefined) {
      currentWorkPlaneABC.z = Number.POSITIVE_INFINITY;
    }
  }
}

/** Output block to do safe retract and/or move to home position. */
function writeRetract() {
  if (arguments.length == 0) {
    error(localize("No axis specified for writeRetract()."));
    return;
  }
  var words = []; // store all retracted axes in an array
  for (var i = 0; i < arguments.length; ++i) {
    let instances = 0; // checks for duplicate retract calls
    for (var j = 0; j < arguments.length; ++j) {
      if (arguments[i] == arguments[j]) {
        ++instances;
      }
    }
    if (instances > 1) { // error if there are multiple retract calls for the same axis
      error(localize("Cannot retract the same axis twice in one line"));
      return;
    }
    switch (arguments[i]) {
    case X:
      xOutput.reset();
      words.push(xOutput.format(getProperty("homePositionX")));
      break;
    case Y:
      yOutput.reset();
      words.push(yOutput.format(getProperty("homePositionY")));
      break;
    case Z:
      zOutput.reset();
      words.push(zOutput.format(getProperty("homePositionZ")));
      break;
    default:
      error(localize("Bad axis specified for writeRetract()."));
      return;
    }
  }
  if (words.length > 0) {
    writeBlock(gMotionModal.format(0), words); // retract
  }
}

function onDwell(seconds) {
  if (seconds > 9999.99) {
    warning(localize("Dwelling time is out of range."));
  }
  writeBlock(gFormat.format(4), dwellFormat.format(seconds));
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

var resetFeed = false;

function getHighfeedrate(radius) {
  if (currentSection.feedMode == FEED_PER_REVOLUTION) {
    if (toDeg(radius) <= 0) {
      radius = toPreciseUnit(0.1, MM);
    }
    var rpm = spindleSpeed; // rev/min
    if (currentSection.getTool().getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
      var O = 2 * Math.PI * radius; // in/rev
      rpm = tool.surfaceSpeed / O; // in/min div in/rev => rev/min
    }
    return highFeedrate / rpm; // in/min div rev/min => in/rev
  }
  return highFeedrate;
}

function onRapid(_x, _y, _z) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    var useG1 = (((((x ? 1 : 0) + (y ? 1 : 0) + (z ? 1 : 0)) > 1)) || machineState.usePolarInterpolation) && !isCannedCycle;
    // axes are not synchronized
    if (useG1) {
      var highFeed = machineState.usePolarInterpolation ? toPreciseUnit(1500, MM) : getHighfeedrate(_x);
      if (x) {
        xOutput.reset();
      }
      if (y) {
        yOutput.reset();
      }
      if (z) {
        zOutput.reset();
      }
      onExpandedLinear(_x, _y, _z, highFeed);
    } else {
      writeBlock(gMotionModal.format(0), x, y, z);
    }
  }
}

function onLinear(_x, _y, _z, feed) {
  if (isSpeedFeedSynchronizationActive()) {
    resetFeed = true;
    var threadPitch = getParameter("operation:threadPitch");
    var threadsPerInch = 1.0 / threadPitch; // per mm for metric
    var startXYZ = getCurrentPosition();
    var deltaX = spatialFormat.getResultingValue(_x - startXYZ.x);
    writeBlock(
      gMotionModal.format(31),
      xOutput.format(_x),
      yOutput.format(_y),
      zOutput.format(_z),
      iOutput.format(deltaX),
      pitchOutput.format(1 / threadsPerInch)
    );
    return;
  }
  if (resetFeed) {
    resetFeed = false;
    forceFeed();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    var linearCode = (machineState.usePolarInterpolation && (x || y)) ? 101 : 1;
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      if (machineState.isTurningOperation) {
        writeBlock(gPlaneModal.format(18));
      } else if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1))) {
        writeBlock(gPlaneModal.format(getG17Code()));
      } else if (Vector.dot(currentSection.workPlane.forward, new Vector(0, 0, 1)) < 1e-7) {
        writeBlock(gPlaneModal.format(19));
      } else {
        error(localize("Tool orientation is not supported for radius compensation."));
        return;
      }
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(
          gMotionModal.format(linearCode),
          gFormat.format(41),
          x, y, z, getFeed(feed));
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(
          gMotionModal.format(linearCode),
          gFormat.format(42),
          x, y, z, getFeed(feed));
        break;
      default:
        writeBlock(gMotionModal.format(linearCode), gFormat.format(40), x, y, z, getFeed(feed));
      }
    } else {
      writeBlock(gMotionModal.format(linearCode), x, y, z, getFeed(feed));
    }
  }
}

function onRapid5D(_x, _y, _z, _a, _b, _c) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation mode cannot be changed at rapid traversal."));
    return;
  }

  setCAxisDirection(cOutput.getCurrent(), _c);

  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = aOutput.format(_a);
  var b = bOutput.format(_b);
  var c = cOutput.format(_c);
  if (x || y || z || a || b || c) {
    var useG1 = (((x ? 1 : 0) + (y ? 1 : 0) + (z ? 1 : 0)) + (a ? 1 : 0) + (b ? 1 : 0) + (c ? 1 : 0) > 1);
    var gCode = useG1 ? 1 : 0;
    var f = useG1 ? (getFeed(machineState.usePolarInterpolation ? toPreciseUnit(1500, MM) : getHighfeedrate(_x))) : "";
    writeBlock(gMotionModal.format(gCode), x, y, z, a, b, c, f);
    if (!useG1) {
      forceFeed();
    }
  }
}

function onLinear5D(_x, _y, _z, _a, _b, _c, feed) {
  var compCode = undefined;
  if (pendingRadiusCompensation >= 0) {
    if (isPolarModeActive()) {
      pendingRadiusCompensation = -1;
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        compCode = gFormat.format(41);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        compCode = gFormat.format(42);
        break;
      default:
        compCode = gFormat.format(40);
      }
    } else {
      error(localize("Radius compensation cannot be activated/deactivated for 5-axis move."));
    }
  }

  setCAxisDirection(cOutput.getCurrent(), _c);

  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = aOutput.format(_a);
  var b = bOutput.format(_b);
  var c = cOutput.format(_c);

  if (x || y || z || a || b || c) {
    writeBlock(gMotionModal.format(1), x, y, z, a, b, c, getFeed(feed));
  }
}

// Start of Polar coordinates
var defaultPolarCoordinatesDirection = new Vector(1, 0, 0); // default direction for polar interpolation
var polarCoordinatesDirection = defaultPolarCoordinatesDirection; // vector to maintain tool at while in polar interpolation
var polarSpindleAxisSave;
function setPolarCoordinates(mode) {
  if (!mode) { // turn off polar mode if required
    if (isPolarModeActive()) {
      deactivatePolarMode();
      if (gotBAxis) {
        machineConfiguration.setSpindleAxis(polarSpindleAxisSave);
        bOutput.enable();
      }
      // setPolarFeedMode(false);
      if (currentWorkPlaneABC != undefined) {
        currentWorkPlaneABC.z = Number.POSITIVE_INFINITY;
      }
    }
    polarCoordinatesDirection = defaultPolarCoordinatesDirection; // reset when deactivated
    return;
  }

  var direction = polarCoordinatesDirection;

  // determine the rotary axis to use for Polar coordinates
  var axis = undefined;
  if (machineConfiguration.getAxisV().isEnabled()) {
    if (Vector.dot(machineConfiguration.getAxisV().getAxis(), currentSection.workPlane.getForward()) != 0) {
      axis = machineConfiguration.getAxisV();
    }
  }
  if (axis == undefined && machineConfiguration.getAxisU().isEnabled()) {
    if (Vector.dot(machineConfiguration.getAxisU().getAxis(), currentSection.workPlane.getForward()) != 0) {
      axis = machineConfiguration.getAxisU();
    }
  }
  if (axis == undefined) {
    error(localize("Polar coordinates require an active rotary axis be defined in direction of workplane normal."));
  }

  // calculate directional vector from initial position
  if (direction == undefined) {
    error(localize("Polar coordinates initiated without a directional vector."));
    return;
  }

  // activate polar coordinates
  // setPolarFeedMode(true); // enable multi-axis feeds for polar mode

  if (gotBAxis) {
    polarSpindleAxisSave = machineConfiguration.getSpindleAxis();
    machineConfiguration.setSpindleAxis(new Vector(0, 0, 1));
    bOutput.disable();
  }
  activatePolarMode(getTolerance(), 0, direction);
  var polarPosition = getPolarPosition(currentSection.getInitialPosition().x, currentSection.getInitialPosition().y, currentSection.getInitialPosition().z);
  setCurrentPositionAndDirection(polarPosition);
}

function getPolarCoordinates(position, abc) {
  var reset = false;
  var current = getCurrentDirection();
  if (!isPolarModeActive()) {
    setCurrentDirection(abc);
    var tempPolarCoordinatesDirection = (currentSection.machiningType && (currentSection.machiningType == MACHINING_TYPE_POLAR)) ? currentSection.polarDirection : polarCoordinatesDirection;
    activatePolarMode(getTolerance() / 2, 0, tempPolarCoordinatesDirection);
    reset = true;
  }
  var polarPosition = getPolarPosition(position.x, position.y, position.z);
  if (reset) {
    deactivatePolarMode();
    setCurrentDirection(current);
  }
  return polarPosition;
}
// End of polar coordinates

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  var directionCode = clockwise ? 2 : 3;
  directionCode += (machineState.usePolarCoordinates || machineState.usePolarInterpolation) ? 100 : 0;

  if (getSpindle(TOOL) == SPINDLE_LIVE) {
    if (machineState.machiningDirection == MACHINING_DIRECTION_AXIAL) {
      if (getCircularPlane() != PLANE_XY) {
        linearize(tolerance);
        return;
      }
    } else {
      if (getCircularPlane() != PLANE_YZ) {
        linearize(tolerance);
        return;
      }
    }
  }
  var toler = getTolerance();

  if (isSpeedFeedSynchronizationActive()) {
    error(localize("Speed-feed synchronization is not supported for circular moves."));
    return;
  }

  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
    return;
  }

  var start = getCurrentPosition();

  if (isFullCircle()) {
    if (getProperty("useRadius") || isHelical() || machineState.usePolarInterpolation) { // radius mode does not support full arcs
      linearize(toler);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      xOutput.reset();
      yOutput.reset();
      writeBlock(gPlaneModal.format(getG17Code()), gMotionModal.format(directionCode), iOutput.format(cx - start.x), jOutput.format(cy - start.y), getFeed(feed));
      break;
    case PLANE_ZX:
      if (machineState.usePolarInterpolation) {
        linearize(tolerance);
        return;
      }
      zOutput.reset();
      xOutput.reset();
      writeBlock(gPlaneModal.format(18), gMotionModal.format(directionCode), iOutput.format(cx - start.x), kOutput.format(cz - start.z), getFeed(feed));
      break;
    case PLANE_YZ:
      if (machineState.usePolarInterpolation) {
        linearize(tolerance);
        return;
      }
      yOutput.reset();
      zOutput.reset();
      writeBlock(gPlaneModal.format(19), gMotionModal.format(directionCode), jOutput.format(cy - start.y), kOutput.format(cz - start.z), getFeed(feed));
      break;
    default:
      linearize(toler);
    }
  } else if (!getProperty("useRadius") && !machineState.usePolarInterpolation) {
    if (isHelical() && ((getCircularSweep() < toRad(30)) || (getHelicalPitch() > 10))) { // avoid G112 issue
      linearize(toler);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      xOutput.reset();
      yOutput.reset();
      writeBlock(gPlaneModal.format(getG17Code()), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x), jOutput.format(cy - start.y), getFeed(feed));
      break;
    case PLANE_ZX:
      if (machineState.usePolarInterpolation) {
        linearize(tolerance);
        return;
      }
      zOutput.reset();
      xOutput.reset();
      writeBlock(gPlaneModal.format(18), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x), kOutput.format(cz - start.z), getFeed(feed));
      break;
    case PLANE_YZ:
      if (machineState.usePolarInterpolation) {
        linearize(tolerance);
        return;
      }
      yOutput.reset();
      zOutput.reset();
      writeBlock(gPlaneModal.format(19), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y), kOutput.format(cz - start.z), getFeed(feed));
      break;
    default:
      linearize(toler);
    }
  } else { // use radius mode
    if (isHelical() && ((getCircularSweep() < toRad(30)) || (getHelicalPitch() > 10) || machineState.usePolarInterpolation)) {
      linearize(toler);
      return;
    }
    var r = getCircularRadius();
    if (toDeg(getCircularSweep()) > (180 + 1e-9)) {
      linearize(toler);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      xOutput.reset();
      yOutput.reset();
      writeBlock(gPlaneModal.format(getG17Code()), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "L" + rFormat.format(r), getFeed(feed));
      break;
    case PLANE_ZX:
      if (machineState.usePolarInterpolation) {
        linearize(tolerance);
        return;
      }
      zOutput.reset();
      xOutput.reset();
      writeBlock(gPlaneModal.format(18), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "L" + rFormat.format(r), getFeed(feed));
      break;
    case PLANE_YZ:
      if (machineState.usePolarInterpolation) {
        linearize(tolerance);
        return;
      }
      yOutput.reset();
      zOutput.reset();
      writeBlock(gPlaneModal.format(19), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "L" + rFormat.format(r), getFeed(feed));
      break;
    default:
      linearize(toler);
    }
  }
}

var chuckMachineFrame;
var chuckSubPosition;
function getSecondaryPullMethod(type) {
  var pullMethod = {};

  // determine if pull operation, spindle return, or both
  pullMethod.pull = false;
  pullMethod.home = false;

  switch (type) {
  case "secondary-spindle-pull":
    pullMethod.pullPosition = chuckSubPosition + cycle.pullingDistance;
    pullMethod.machineFrame = chuckMachineFrame;
    pullMethod.unclampMode = "keep-clamped";
    pullMethod.pull = true;
    break;
  case "secondary-spindle-return":
    pullMethod.pullPosition = cycle.feedPosition;
    pullMethod.machineFrame = cycle.useMachineFrame;
    pullMethod.unclampMode = cycle.unclampMode;

    // pull part only (when offset!=0), Return secondary spindle to home (when offset=0)
    var feedDis = 0;
    if (pullMethod.machineFrame) {
      if (hasParameter("operation:feedPlaneHeight_direct")) { // Inventor
        feedDis = getParameter("operation:feedPlaneHeight_direct");
      } else if (hasParameter("operation:feedPlaneHeightDirect")) { // HSMWorks
        feedDis = getParameter("operation:feedPlaneHeightDirect");
      }
      feedPosition = feedDis;
    } else if (hasParameter("operation:feedPlaneHeight_offset")) { // Inventor
      feedDis = getParameter("operation:feedPlaneHeight_offset");
    } else if (hasParameter("operation:feedPlaneHeightOffset")) { // HSMWorks
      feedDis = getParameter("operation:feedPlaneHeightOffset");
    }

    // Transfer part to secondary spindle
    if (pullMethod.unclampMode != "keep-clamped") {
      pullMethod.pull = feedDis != 0;
      pullMethod.home = true;
    } else {
      // pull part only (when offset!=0), Return secondary spindle to home (when offset=0)
      pullMethod.pull = feedDis != 0;
      pullMethod.home = !pullMethod.pull;
    }
    break;
  }
  return pullMethod;
}

var wAxisTorqueUpper = 30;
var wAxisTorqueMiddle = 25;
var wAxisTorqueLower = 5;

// CUSTOM: bar puller minimum-Z tracking. Tracks the most-negative Z that any
// machining operation has reached in the current part WCS frame, so the tool-based
// bar puller can grip on unmachined stock without colliding with prior features.
// For radial (G19) machining the tool body extends `tool.diameter/2` past the
// commanded Z toward the chuck, so that radius is subtracted when accumulating.
// After a bar pull, the stock has physically shifted +Z by the pulling distance,
// so the tracker is incremented by that same amount.
var minMachinedZ; // undefined until first updated

// CUSTOM: when true, the previous section's onSectionEnd has already emitted
// the bar-pull prelude (spindle stop, coolant off, optional stop, retracts)
// for the upcoming bar-pull section, so writeToolBarPullerCycle should skip
// re-emitting them. Reset back to false after consumption.
var barPullPreludeEmitted = false;

// CUSTOM: when true, the bar-pull section just wrote its own complete wrap-up
// (retract X, retract Z, optional stop) at the end of writeToolBarPullerCycle,
// so the next section's onSection should skip its normal previous-section
// wrap-up to avoid emitting duplicate home/M1 blocks. Reset after consumption.
var barPullWroteOwnWrapup = false;

function getInitialMinMachinedZ() {
  // Default to the front face of the original stock workpiece, if available.
  try {
    var wp = getWorkpiece();
    if (wp && wp.upper && isFinite(wp.upper.z)) {
      return wp.upper.z;
    }
  } catch (e) {}
  return 0;
}

function updateMinMachinedZ() {
  if (!getProperty("useToolBarPuller")) {
    return;
  }
  if (currentSection == undefined) {
    return;
  }
  // Skip bar-pull / sub-spindle cycle sections -- they don't machine stock and
  // writeToolBarPullerCycle() adjusts the tracker explicitly. We detect bar-pull
  // sections directly via currentSection.hasCycle("secondary-spindle-pull"),
  // which is reliable across the section's lifetime. The other sub-spindle
  // cycle-type strings stay as a defensive fallback for any future flow that
  // might expose `operation:cycleType` (today it isn't populated on bar-pull
  // sections in Fusion, so the cycle-type check is silent there).
  if (currentSection.hasCycle && currentSection.hasCycle("secondary-spindle-pull")) {
    return;
  }
  if (machineState.stockTransferIsActive) {
    return;
  }
  if (hasParameter("operation:cycleType")) {
    var ct = getParameter("operation:cycleType");
    if (ct == "secondary-spindle-pull" ||
        ct == "secondary-spindle-return" ||
        ct == "secondary-spindle-grab" ||
        ((typeof isSubSpindleCycle == "function") && isSubSpindleCycle(ct))) {
      return;
    }
  }
  if (minMachinedZ == undefined) {
    minMachinedZ = getInitialMinMachinedZ();
  }
  var zRange = currentSection.getGlobalZRange();
  if (zRange == undefined) {
    return;
  }
  var sectionMinZ = zRange.getMinimum();
  // Radial machining: the cylindrical tool body extends toolRadius past the commanded
  // Z toward the chuck, so the chuck-side machined extent is that much deeper.
  if (getMachiningDirection(currentSection) == MACHINING_DIRECTION_RADIAL) {
    var t = currentSection.getTool();
    if (t) {
      sectionMinZ -= t.diameter / 2;
    }
  }
  if (sectionMinZ < minMachinedZ) {
    minMachinedZ = sectionMinZ;
  }
}

// CUSTOM: tool-based bar puller. Emit a complete bar-pull routine using a tool with
// gripping fingers instead of relying on a secondary spindle. The puller tool's X
// offset must be set so that X0 places the fingers at the ideal grip position; the
// tool's Z offset is calibrated normally (program Z matches the part WCS Z). The
// grip Z is computed from the tracked minimum machined Z plus 'Bar puller Z offset'.
function writeToolBarPullerCycle() {
  if (cycleType != "secondary-spindle-pull") {
    error(localize("Tool-based bar puller only supports the 'Bar Pull' (secondary-spindle-pull) cycle. Disable 'Use tool-based bar puller' or remove the unsupported cycle."));
    return;
  }
  var pullDistance = cycle.pullingDistance;
  if (!(pullDistance > 0)) {
    error(localize("Bar puller pulling distance must be greater than zero."));
    return;
  }
  var toolNumber = getProperty("toolBarPullerNumber");
  if (!(toolNumber > 0)) {
    error(localize("Set the 'Bar puller tool number' post property."));
    return;
  }
  // Pull feedrate, dwell, and stock diameter all come from the Fusion setup / operation.
  var pullFeed = cycle.feedrate;
  if (!(pullFeed > 0)) {
    error(localize("Bar pull operation must specify a feedrate."));
    return;
  }
  var dwell = cycle.dwell;
  if (!(dwell >= 0)) {
    dwell = 0;
  }
  // Read stock diameter from the active setup's workpiece bounding box.
  var workpiece = getWorkpiece();
  var stockDiameter = Math.max(
    workpiece.upper.x - workpiece.lower.x,
    workpiece.upper.y - workpiece.lower.y
  );
  if (!(stockDiameter > 0)) {
    error(localize("Could not determine stock diameter from the setup workpiece. Configure cylindrical stock on the setup."));
    return;
  }
  var approachRadius = stockDiameter / 2; // xFormat scales radius->diameter on output

  // CUSTOM: compute the grip Z dynamically from tracked machining history.
  // gripZ is in the active part WCS frame (the puller tool's Z offset is set normally
  // so program Z corresponds to the part WCS origin). The configurable offset shifts
  // the grip relative to the chuck-side boundary of the deepest previously-machined
  // feature (i.e. the start of the unmachined region of the bar).
  if (minMachinedZ == undefined) {
    minMachinedZ = getInitialMinMachinedZ();
  }
  var gripZ = minMachinedZ + getProperty("barPullerZOffset");

  writeln("");
  var comment = getParameter("operation-comment", "");
  if (comment) {
    writeComment(comment);
  }
  writeComment("BAR PULL (TOOL-BASED)");

  // CUSTOM: prelude (spindle stop, coolant off, optional stop, retracts) is
  // normally emitted at the tail end of the previous section's onSectionEnd so
  // that it visually belongs to wrapping up the prior operation rather than
  // looking like it lives inside the bar-pull body. Skip if already done.
  if (!barPullPreludeEmitted) {
    onCommand(COMMAND_STOP_SPINDLE);
    onCommand(COMMAND_COOLANT_OFF);
    onCommand(COMMAND_OPTIONAL_STOP);
    writeRetract(X);
    writeRetract(Z);
  }
  barPullPreludeEmitted = false;

  // Tool change to the bar puller tool. The tool's offset register matches its number,
  // matching formatTool() output for maxToolOffset<=99: T<offset1><tool><offset2> with
  // both offsets == tool number (e.g. tool 6 -> T060606). For maxToolOffset>99 use the
  // alternate compact form: T<offset*1000+tool>.
  var pullerToolWord;
  if (getProperty("maxToolOffset") > 99) {
    pullerToolWord = "T" + tool1Format.format(toolNumber * 1000 + toolNumber);
  } else {
    pullerToolWord = "T" + tool1Format.format(toolNumber * 10000 + toolNumber * 100 + toolNumber);
  }
  gMotionModal.reset();
  // CUSTOM: emit an N<seqno> on the puller tool change line so the bar-pull
  // section's tool call matches the appearance of every other section's tool
  // change (e.g. "N4 T070707"). Mirrors the trick used in onSection right
  // before its own writeBlock(formatTool(tool, false)).
  if (getProperty("showSequenceNumbers") == "toolChange") {
    showSequenceNumbers = "true";
  }
  writeBlock(pullerToolWord);

  // Force feed/min mode and reset modals before positioning.
  gFeedModeModal.reset();
  feedOutput.reset();
  xOutput.reset();
  zOutput.reset();
  writeBlock(gFeedModeModal.format(getCode("FEED_MODE_UNIT_MIN", getSpindle(TOOL))));

  // Rapid to approach position: X at stock diameter, then Z at the computed grip position.
  writeBlock(gMotionModal.format(0), xOutput.format(approachRadius));
  writeBlock(gMotionModal.format(0), zOutput.format(gripZ));

  // Feed onto the bar (X0 = ideal grip position on the fingers).
  writeBlock(gMotionModal.format(1), xOutput.format(0), feedOutput.format(pullFeed));

  // Unclamp the main chuck, dwell to let it release.
  writeBlock(mFormat.format(getCode("UNCLAMP_CHUCK", SPINDLE_MAIN)), formatComment("UNCLAMP MAIN CHUCK"));
  if (dwell > 0) {
    onDwell(dwell);
  }

  // Feed the bar out by the requested pulling distance (+Z = away from chuck).
  writeBlock(gMotionModal.format(1), zOutput.format(gripZ + pullDistance), feedOutput.format(pullFeed));

  // Clamp the main chuck back onto the bar, dwell to let it grip.
  writeBlock(mFormat.format(getCode("CLAMP_CHUCK", SPINDLE_MAIN)), formatComment("CLAMP MAIN CHUCK"));
  if (dwell > 0) {
    onDwell(dwell);
  }

  // Feed back out to stock diameter to clear the fingers, then rapid home.
  writeBlock(gMotionModal.format(1), xOutput.format(approachRadius), feedOutput.format(pullFeed));

  // CUSTOM: bar-pull section's own wrap-up. Matches the canonical order used
  // for every other section: retract X, retract Z, optional stop -- so the
  // bar-pull section ends at home with an M01 just like a turning or drilling
  // section. The next section's onSection will see barPullWroteOwnWrapup=true
  // and skip its own previous-section wrap-up to avoid duplicating these.
  writeRetract(X);
  writeRetract(Z);
  onCommand(COMMAND_OPTIONAL_STOP);
  barPullWroteOwnWrapup = true;

  // CUSTOM: the stock has physically shifted +Z by pullDistance, so every previously
  // tracked machined feature moves with it. Slide the tracker accordingly.
  minMachinedZ += pullDistance;
}

function onCycle() {
  // CUSTOM: tool-based bar puller short-circuit.
  if (getProperty("useToolBarPuller") &&
      (typeof isSubSpindleCycle == "function") && isSubSpindleCycle(cycleType)) {
    writeToolBarPullerCycle();
    return;
  }
  if ((typeof isSubSpindleCycle == "function") && isSubSpindleCycle(cycleType)) {
    if (!gotSecondarySpindle) {
      error(localize("Secondary spindle is not available."));
    }
    writeln("");
    var comment = getParameter("operation-comment", "");
    if (comment) {
      writeComment(comment);
    }

    // Start of stock transfer operation(s)
    if (!machineState.stockTransferIsActive) {
      onCommand(COMMAND_STOP_SPINDLE);
      onCommand(COMMAND_COOLANT_OFF);
      onCommand(COMMAND_OPTIONAL_STOP);
      if (cycle.stopSpindle) {
        writeBlock(mFormat.format(getCode("ENABLE_C_AXIS", getSpindle(PART))));
        onCommand(COMMAND_UNLOCK_MULTI_AXIS);
        writeBlock(gMotionModal.format(0), cOutput.format(0));
        onCommand(COMMAND_LOCK_MULTI_AXIS);
        // writeBlock(mFormat.format(getCode("DISABLE_C_AXIS", getSpindle(PART)))); // cannot disable C-axis when it's locked
      }
      gFeedModeModal.reset();
      var feedMode;
      if (currentSection.feedMode == FEED_PER_REVOLUTION) {
        feedMode = gFeedModeModal.format(getCode("FEED_MODE_UNIT_REV", getSpindle(TOOL)));
      } else {
        feedMode = gFeedModeModal.format(getCode("FEED_MODE_UNIT_MIN", getSpindle(TOOL)));
      }
    }

    switch (cycleType) {
    case "secondary-spindle-grab":
      if (currentSection.partCatcher) {
        engagePartCatcher(true);
      }
      writeBlock(mFormat.format(getCode("INTERNAL_INTERLOCK_ON", getSecondarySpindle())), formatComment("SUB CHUCK INTERLOCK RELEASE ON"));
      writeBlock(mFormat.format(getCode("INTERNAL_INTERLOCK_ON", getSpindle(PART))), formatComment("MAIN CHUCK INTERLOCK RELEASE ON"));
      writeBlock(mFormat.format(getCode("UNCLAMP_CHUCK", getSecondarySpindle())), formatComment("UNCLAMP OPPOSITE SPINDLE"));
      onDwell(cycle.dwell);
      gSpindleModeModal.reset();

      if (cycle.stopSpindle) { // no spindle rotation
        // do nothing
      } else { // spindle rotation
        var transferCodes = getSpindleTransferCodes();

        // Write out maximum spindle speed
        if (transferCodes.spindleMode == SPINDLE_CONSTANT_SURFACE_SPEED) {
          var maximumSpindleSpeed = (transferCodes.maximumSpindleSpeed > 0) ? Math.min(transferCodes.maximumSpindleSpeed, getProperty("maximumSpindleSpeed")) : getProperty("maximumSpindleSpeed");
          writeBlock(gFormat.format(50), maxSpeedOutput.format(maximumSpindleSpeed));
        }
        // write out spindle speed
        var _spindleSpeed;
        var spindleMode;
        if (transferCodes.spindleMode == SPINDLE_CONSTANT_SURFACE_SPEED) {
          _spindleSpeed = transferCodes.surfaceSpeed * ((unit == MM) ? 1 / 1000.0 : 1 / 12.0);
          spindleMode = getCode("CONSTANT_SURFACE_SPEED_ON", getSpindle(PART));
        } else {
          _spindleSpeed = cycle.spindleSpeed;
          spindleMode = getCode("CONSTANT_SURFACE_SPEED_OFF", getSpindle(PART));
        }
        writeBlock(
          gSpindleModeModal.format(spindleMode),
          sOutput.format(_spindleSpeed),
          mFormat.format(transferCodes.direction)
        );
        writeBlock(mFormat.format(getCode("SPINDLE_SYNCHRONIZATION_SPEED", getSpindle(PART))), formatComment("SYNCHRONIZED ROTATION ON"));
        writeBlock(mFormat.format(getCode("IGNORE_SPINDLE_ORIENTATION", getSpindle(PART))), formatComment("IGNORE SPINDLE ORIENTATION"));
      }

      gMotionModal.reset();
      var upperZ = getParameter("stock-upper-z");
      writeBlock(gMotionModal.format(0), wOutput.format(cycle.feedPosition));
      if (getProperty("transferUseTorque")) {
        writeBlock(gFormat.format(getCode("TORQUE_LIMIT_ON", getSpindle(PART))), "PW=" + integerFormat.format(wAxisTorqueUpper));
        writeBlock(
          gFormat.format(getCode("TORQUE_SKIP_ON", getSpindle(PART))),
          wOutput.format(cycle.chuckPosition),
          "D" + zFormat.format(cycle.feedPosition - cycle.chuckPosition),
          "L" + zFormat.format(cycle.feedPosition - upperZ),
          getFeed(cycle.feedrate),
          "PW=" + integerFormat.format(wAxisTorqueMiddle)
        );
        writeBlock(gFormat.format(getCode("TORQUE_LIMIT_ON", getSpindle(PART))), "PW=" + integerFormat.format(wAxisTorqueLower));
        writeBlock(gFormat.format(getCode("TORQUE_LIMIT_OFF", getSpindle(PART))));
      } else {
        writeBlock(gMotionModal.format(1), wOutput.format(cycle.chuckPosition), getFeed(cycle.feedrate));
        onDwell(cycle.dwell);
      }
      writeBlock(mFormat.format(getCode("CLAMP_CHUCK", getSecondarySpindle())), formatComment("CLAMP SUB SPINDLE"));
      onDwell(cycle.dwell);
      chuckMachineFrame = cycle.useMachineFrame;
      chuckSubPosition = cycle.chuckPosition;
      machineState.stockTransferIsActive = true;
      break;
    case "secondary-spindle-return":
    case "secondary-spindle-pull":
      var pullMethod = getSecondaryPullMethod(cycleType);
      if (!machineState.stockTransferIsActive) {
        if (pullMethod.pull) {
          error(localize("The part must be chucked prior to a pull operation."));
          return;
        }
      }

      // bar pull
      if (pullMethod.pull) {
        writeBlock(mFormat.format(getCode("UNCLAMP_CHUCK", getSpindle(PART))), formatComment("UNCLAMP MAIN CHUCK"));
        onDwell(cycle.dwell);
        writeBlock(
          gMotionModal.format(1),
          wOutput.format(pullMethod.pullPosition),
          getFeed(cycle.feedrate),
          formatComment("BAR PULL")
        );
      }

      // move subspindle to home
      if (pullMethod.home) {
        if (pullMethod.unclampMode == "unclamp-secondary") { // simple bar pulling operation
          writeBlock(mFormat.format(getCode("CLAMP_CHUCK", getSpindle(PART))), formatComment("CLAMP MAIN CHUCK"));
          onDwell(cycle.dwell);
          writeBlock(mFormat.format(getCode("UNCLAMP_CHUCK", getSecondarySpindle())), formatComment("UNCLAMP SUB CHUCK"));
          onDwell(cycle.dwell);
        }
        writeBlock(
          gMotionModal.format(0),
          wOutput.format(getProperty("homePositionW")),
          formatComment("SUB SPINDLE RETURN")
        );
        writeBlock(mFormat.format(getCode("INTERNAL_INTERLOCK_OFF", getSpindle(PART))), formatComment("MAIN CHUCK INTERLOCK RELEASE OFF"));
        writeBlock(mFormat.format(getCode("INTERNAL_INTERLOCK_OFF", getSecondarySpindle())), formatComment("SUB CHUCK INTERLOCK RELEASE OFF"));
      } else {
        writeBlock(mFormat.format(getCode("CLAMP_CHUCK", getSpindle(PART))), formatComment("CLAMP MAIN CHUCK"));
        onDwell(cycle.dwell);
      }
      machineState.stockTransferIsActive = true;
      break;
    }
  }

  if (cycleType == "stock-transfer") {
    warning(localize("Stock transfer is not supported. Required machine specific customization."));
    return;
  }
}

var isCannedCycle = false;
function onCyclePath() {
  saveShowSequenceNumbers = showSequenceNumbers;
  var verticalPasses;
  if (cycle.profileRoughingCycle == 0) {
    verticalPasses = false;
  } else if (cycle.profileRoughingCycle == 1) {
    verticalPasses = true;
  } else {
    error(localize("Unsupported passes type."));
    return;
  }
  isCannedCycle = true;
  // buffer all paths and stop feeds being output
  feedOutput.disable();
  showSequenceNumbers = "false";
  redirectToBuffer();
  writeBlock("NAT" + getCurrentSectionId() + " " + (verticalPasses ? "G82" : "G81"));
  gMotionModal.reset();
  xOutput.reset();
  zOutput.reset();
}

function onCyclePathEnd() {
  writeBlock(gFormat.format(80));
  showSequenceNumbers = saveShowSequenceNumbers; // reset property to initial state
  feedOutput.enable();
  var cyclePath = String(getRedirectionBuffer()).split(EOL); // get cycle path from buffer
  closeRedirection();
  for (line in cyclePath) { // remove empty elements
    if (cyclePath[line] == "") {
      cyclePath.splice(line);
    }
  }

  // output cycle data
  switch (cycleType) {
  case "turning-canned-rough":
    writeBlock(gFormat.format(85), "NAT" + getCurrentSectionId() +
        " D" + spatialFormat.format(cycle.depthOfCut) +
        " U" + xFormat.format(Math.abs(cycle.xStockToLeave)) +
        " W" + spatialFormat.format(Math.abs(cycle.zStockToLeave)) +
        " " + getFeed(cycle.cutfeedrate)
    );
    break;
  default:
    error(localize("Unsupported turning canned cycle."));
  }

  for (var i = 0; i < cyclePath.length; ++i) {
    if (i == 0) {
      writeln(cyclePath[i]);
    } else {
      writeBlock(cyclePath[i]); // output cycle path
    }
    showSequenceNumbers = saveShowSequenceNumbers; // reset property to initial state
    isCannedCycle = false;
  }
}

function getCommonCycle(x, y, z, r) {
  if (machineState.usePolarCoordinates) {
    var polarPosition = getPolarPosition(x, y, z);
    setCurrentPositionAndDirection(polarPosition);
    // setCAxisDirection(cOutput.getCurrent(), currentC); // causes extra hole to be drilled & manual recommends using a single direction for accuracy
    xOutput.reset();
    zOutput.reset();
    cOutput.reset();
    return [xOutput.format(polarPosition.first.x), cOutput.format(polarPosition.second.z),
      zOutput.format(polarPosition.first.z),
      conditional(r != 0, (gPlaneModal.getCurrent() == 17 ? "K" : "I") + spatialFormat.format(r))];
  } else {
    return [xOutput.format(x), yOutput.format(y),
      zOutput.format(z),
      conditional(r != 0, (gPlaneModal.getCurrent() == 17 ? "K" : "I") + spatialFormat.format(r))];
  }
}

function writeCycleClearance(plane, clearance) {
  if (true) {
    onCycleEnd();
    switch (plane) {
    case 17:
      writeBlock(gMotionModal.format(0), zOutput.format(clearance));
      break;
    case 18:
      writeBlock(gMotionModal.format(0), yOutput.format(clearance));
      break;
    case 19:
      writeBlock(gMotionModal.format(0), xOutput.format(clearance));
      break;
    default:
      error(localize("Unsupported drilling orientation."));
      return;
    }
  }
}

var threadStart;
var threadEnd;
function moveToThreadStart(x, y, z) {
  var cuttingAngle = 0;
  if (hasParameter("operation:infeedAngle")) {
    cuttingAngle = getParameter("operation:infeedAngle");
  }
  if (cuttingAngle != 0) {
    var zz;
    if (isFirstCyclePoint()) {
      threadStart = getCurrentPosition();
      threadEnd = new Vector(x, y, z);
    } else {
      var zz = threadStart.z - (Math.abs(threadEnd.x - x) * Math.tan(toRad(cuttingAngle)));
      writeBlock(gMotionModal.format(0), zOutput.format(zz));
      threadStart.setZ(zz);
      threadEnd = new Vector(x, y, z);
    }
  }
}

var skipThreading = false;
function onCyclePoint(x, y, z) {

  if (!getProperty("useCycles") || currentSection.isMultiAxis()) {
    expandCyclePoint(x, y, z);
    return;
  }

  var plane = gPlaneModal.getCurrent();
  if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1)) ||
      isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, -1))) {
    plane = 17; // XY plane
  } else if (Vector.dot(currentSection.workPlane.forward, new Vector(0, 0, 1)) < 1e-7) {
    plane = 19; // YZ plane
  } else {
    expandCyclePoint(x, y, z);
    return;
  }

  switch (cycleType) {
  case "thread-turning":
    if (skipThreading) { // HSM outputs multiple cycles for multi-start threading
      return;
    }
    var numberOfThreads = 1;
    if ((hasParameter("operation:doMultipleThreads") && (getParameter("operation:doMultipleThreads") != 0))) {
      numberOfThreads = getParameter("operation:numberOfThreads");
    }
    if ((getProperty("useSimpleThread") &&
      !(hasParameter("operation:doMultipleThreads") && (getParameter("operation:doMultipleThreads") != 0)))) {
      moveToThreadStart(x, y, z);
      gCycleModal.reset();
      zOutput.reset();
      writeBlock(
        gCycleModal.format(33),
        xOutput.format(x - cycle.incrementalX),
        zOutput.format(z),
        iOutput.format(cycle.incrementalX),
        pitchOutput.format(cycle.pitch)
      );
    } else {
      if (isLastCyclePoint()) {
        var threadHeight = getParameter("operation:threadDepth");
        var firstDepthOfCut = cycle.firstPassDepth ? cycle.firstPassDepth : threadHeight - Math.abs(getCyclePoint(0).x - x);
        var cuttingAngle = 0;
        if (hasParameter("operation:infeedAngle")) {
          cuttingAngle = getParameter("operation:infeedAngle");
        }

        var threadInfeedMode = "constant";
        if (hasParameter("operation:infeedMode")) {
          threadInfeedMode = getParameter("operation:infeedMode");
        }
        var infeedModeCode = 0;
        var threadCuttingMode = 0;
        if (threadInfeedMode == "reduced") {
          threadCuttingMode = 32;
          infeedModeCode = 75;
        } else if (threadInfeedMode == "constant") {
          threadCuttingMode = 32;
          infeedModeCode = 73;
        } else if (threadInfeedMode == "alternate") {
          threadCuttingMode = 33;
          infeedModeCode = 75;
        } else {
          error(localize("Unsupported Infeed Mode."));
          return;
        }

        writeBlock(
          gCycleModal.format(71),
          xOutput.format(x),
          zOutput.format(z),
          // "A" + taperFormat.format(Math.atan2(cycle.incrementalX, cycle.incrementalZ * -1)), // taper angle instead of I
          cuttingAngle != 0 ? "B" + zFormat.format(cuttingAngle * 2) : "",
          "D" + xFormat.format(firstDepthOfCut),
          "H" + xFormat.format(threadHeight), // output as diameter
          iOutput.format(cycle.incrementalX),
          numberOfThreads > 1 ? "Q" + numberOfThreads : "",
          feedOutput.format(cycle.pitch),
          mFormat.format(threadCuttingMode),
          mFormat.format(infeedModeCode)
        );
        skipThreading = (numberOfThreads != 0);
        gMotionModal.reset();
      }
    }
    return;
  }

  var lockCode = "";

  var rapto = 0;
  if (isFirstCyclePoint()) { // first cycle point
    rapto = cycle.clearance - cycle.retract;

    var P = !cycle.dwell ? 0 : clamp(1, cycle.dwell, 99999999); // in seconds

    switch (cycleType) {
    case "drilling":
      writeCycleClearance(plane, cycle.clearance);
      xOutput.reset();
      zOutput.reset();
      writeBlock(
        gCycleModal.format(machineState.axialCenterDrilling ? 74 : 181),
        getCommonCycle(x, y, z, rapto),
        "D" + spatialFormat.format(cycle.depth + cycle.retract - cycle.stock),
        getFeed(cycle.feedrate)
      );
      break;
    case "counter-boring":
      writeCycleClearance(plane, cycle.clearance);
      xOutput.reset();
      zOutput.reset();
      writeBlock(
        gCycleModal.format(machineState.axialCenterDrilling ? 74 : 182),
        getCommonCycle(x, y, z, rapto),
        "D" + spatialFormat.format(cycle.depth + cycle.retract - cycle.stock),
        P > 0 ? eOutput.format(P) : "",
        getFeed(cycle.feedrate)
      );
      break;
    case "deep-drilling":
      writeCycleClearance(plane, cycle.clearance);
      xOutput.reset();
      zOutput.reset();
      writeBlock(
        gCycleModal.format(machineState.axialCenterDrilling ? 74 : 183),
        getCommonCycle(x, y, z, rapto),
        "D" + spatialFormat.format(cycle.incrementalDepth),
        "L" + spatialFormat.format(cycle.incrementalDepth),
        P > 0 ? eOutput.format(P) : "",
        getFeed(cycle.feedrate)
      );
      break;
    case "chip-breaking":
      writeCycleClearance(plane, cycle.clearance);
      xOutput.reset();
      zOutput.reset();
      writeBlock(
        gCycleModal.format(machineState.axialCenterDrilling ? 74 : 183),
        getCommonCycle(x, y, z, rapto),
        "D" + spatialFormat.format(cycle.incrementalDepth),
        cycle.accumulatedDepth > 0 ? "L" + spatialFormat.format(cycle.accumulatedDepth) : "",
        conditional(P > 0, eOutput.format(P)),
        getFeed(cycle.feedrate)
      );
      break;
    case "tapping":
    case "right-tapping":
    case "left-tapping":
      writeCycleClearance(plane, cycle.clearance);
      xOutput.reset();
      zOutput.reset();
      reverseTap = tool.type == TOOL_TAP_LEFT_HAND;
      if (machineState.axialCenterDrilling) {
        if (P != 0) {
          expandCyclePoint(x, y, z);
        } else {
          writeCycleClearance(plane, cycle.retract);
          writeBlock(
            gCycleModal.format(reverseTap ? 78 : 77),
            getCommonCycle(x, y, z, 0),
            getFeed(cycle.feedrate)
          );
          onCommand(COMMAND_START_SPINDLE);
        }
      } else {
        writeCycleClearance(plane, cycle.clearance);
        writeBlock(
          gCycleModal.format(184),
          getCommonCycle(x, y, z, rapto),
          "D" + spatialFormat.format(cycle.depth + cycle.retract - cycle.stock),
          conditional(P > 0, eOutput.format(P)),
          getFeed(cycle.feedrate)
        );
      }
      break;
    case "reaming":
    case "boring":
      if (feedFormat.getResultingValue(cycle.feedrate) != feedFormat.getResultingValue(cycle.retractFeedrate)) {
        expandCyclePoint(x, y, z);
        break;
      }
      writeCycleClearance(plane, cycle.clearance);
      xOutput.reset();
      zOutput.reset();
      writeBlock(
        gCycleModal.format(machineState.axialCenterDrilling ? 74 : 189),
        getCommonCycle(x, y, z, rapto),
        "D" + spatialFormat.format(cycle.depth + cycle.retract - cycle.stock),
        conditional(P > 0, eOutput.format(P)),
        getFeed(cycle.feedrate)
      );
      break;
    default:
      expandCyclePoint(x, y, z);
    }
  } else { // position to subsequent cycle points
    if (cycleExpanded) {
      expandCyclePoint(x, y, z);
    } else {
      var step = 0;
      if (cycleType == "chip-breaking" || cycleType == "deep-drilling") {
        step = cycle.incrementalDepth;
      }
      writeBlock(getCommonCycle(x, y, z, rapto, false), lockCode);
    }
  }
}

function onCycleEnd() {
  // CUSTOM: tool-based bar pull doesn't use a canned drilling cycle, so the
  // trailing G180 cycle-cancel that the stock post would emit here is a stray
  // code that lands after the bar-pull body. Skip it for that cycle type.
  if (getProperty("useToolBarPuller") && cycleType == "secondary-spindle-pull") {
    skipThreading = true;
    return;
  }
  if (!cycleExpanded && !machineState.stockTransferIsActive) {
    writeBlock(gCycleModal.format(180));
    gMotionModal.reset();
  }
  skipThreading = true;
}

function onPassThrough(text) {
  var commands = String(text).split(",");
  for (text in commands) {
    writeBlock(commands[text]);
  }
}

function onParameter(name, value) {
  var invalid = false;
  switch (name) {
  case "action":
    if (String(value).toUpperCase() == "PARTEJECT") {
      ejectRoutine = true;
    } else if (String(value).toUpperCase() == "USEPOLARMODE" ||
        String(value).toUpperCase() == "USEPOLARINTERPOLATION") {
      forcePolarInterpolation = true;
      forcePolarCoordinates = false;
    } else if (String(value).toUpperCase() == "USEXZCMODE" ||
        String(value).toUpperCase() == "USEPOLARCOORDINATES") {
      forcePolarCoordinates = true;
      forcePolarInterpolation = false;
    } else {
      invalid = true;
    }
  }
  if (invalid) {
    error(localize("Invalid action parameter: ") + value);
    return;
  }
}

var currentCoolantMode = COOLANT_OFF;
var currentCoolantTurret = 1;
var coolantOff = undefined;
var isOptionalCoolant = false;
var forceCoolant = false;

function setCoolant(coolant, turret) {
  var coolantCodes = getCoolantCodes(coolant, turret);
  if (Array.isArray(coolantCodes)) {
    if (singleLineCoolant) {
      skipBlock = isOptionalCoolant;
      writeBlock(coolantCodes.join(getWordSeparator()));
    } else {
      for (var c in coolantCodes) {
        skipBlock = isOptionalCoolant;
        writeBlock(coolantCodes[c]);
      }
    }
    return undefined;
  }
  return coolantCodes;
}

function getCoolantCodes(coolant, turret) {
  turret = gotMultiTurret ? (turret == undefined ? 1 : turret) : 1;
  isOptionalCoolant = false;
  var multipleCoolantBlocks = new Array(); // create a formatted array to be passed into the outputted line
  if (!coolants) {
    error(localize("Coolants have not been defined."));
  }
  if (tool.type == TOOL_PROBE) { // avoid coolant output for probing
    coolant = COOLANT_OFF;
  }
  if (coolant == currentCoolantMode && turret == currentCoolantTurret) {
    if ((typeof operationNeedsSafeStart != "undefined" && operationNeedsSafeStart) && coolant != COOLANT_OFF) {
      isOptionalCoolant = true;
    } else if (!forceCoolant || coolant == COOLANT_OFF) {
      return undefined; // coolant is already active
    }
  }
  if ((coolant != COOLANT_OFF) && (currentCoolantMode != COOLANT_OFF) && (coolantOff != undefined) && !forceCoolant && !isOptionalCoolant) {
    if (Array.isArray(coolantOff)) {
      for (var i in coolantOff) {
        multipleCoolantBlocks.push(coolantOff[i]);
      }
    } else {
      multipleCoolantBlocks.push(coolantOff);
    }
  }
  forceCoolant = false;

  var m;
  var coolantCodes = {};
  for (var c in coolants) { // find required coolant codes into the coolants array
    if (coolants[c].id == coolant) {
      var localCoolant = parseCoolant(coolants[c], turret);
      localCoolant = typeof localCoolant == "undefined" ? coolants[c] : localCoolant;
      coolantCodes.on = localCoolant.on;
      if (localCoolant.off != undefined) {
        coolantCodes.off = localCoolant.off;
        break;
      } else {
        for (var i in coolants) {
          if (coolants[i].id == COOLANT_OFF) {
            coolantCodes.off = localCoolant.off;
            break;
          }
        }
      }
    }
  }
  if (coolant == COOLANT_OFF) {
    m = !coolantOff ? coolantCodes.off : coolantOff; // use the default coolant off command when an 'off' value is not specified
  } else {
    coolantOff = coolantCodes.off;
    m = coolantCodes.on;
  }

  if (!m) {
    onUnsupportedCoolant(coolant);
    m = 9;
  } else {
    if (Array.isArray(m)) {
      for (var i in m) {
        multipleCoolantBlocks.push(m[i]);
      }
    } else {
      multipleCoolantBlocks.push(m);
    }
    currentCoolantMode = coolant;
    currentCoolantTurret = turret;
    for (var i in multipleCoolantBlocks) {
      if (typeof multipleCoolantBlocks[i] == "number") {
        multipleCoolantBlocks[i] = mFormat.format(multipleCoolantBlocks[i]);
      }
    }
    return multipleCoolantBlocks; // return the single formatted coolant value
  }
  return undefined;
}

function parseCoolant(coolant, turret) {
  var localCoolant;
  if (getSpindle(TOOL) == SPINDLE_MAIN) {
    localCoolant = turret == 1 ? coolant.spindle1t1 : coolant.spindle1t2;
    localCoolant = typeof localCoolant == "undefined" ? coolant.spindle1 : localCoolant;
  } else if (getSpindle(TOOL) == SPINDLE_LIVE) {
    localCoolant = turret == 1 ? coolant.spindleLivet1 : coolant.spindleLivet2;
    localCoolant = typeof localCoolant == "undefined" ? coolant.spindleLive : localCoolant;
  } else {
    localCoolant = turret == 1 ? coolant.spindle2t1 : coolant.spindle2t2;
    localCoolant = typeof localCoolant == "undefined" ? coolant.spindle2 : localCoolant;
  }
  localCoolant = typeof localCoolant == "undefined" ? (turret == 1 ? coolant.turret1 : coolant.turret2) : localCoolant;
  localCoolant = typeof localCoolant == "undefined" ? coolant : localCoolant;
  return localCoolant;
}

function isSpindleSpeedDifferent() {
  var areDifferent = false;
  if (isFirstSection()) {
    areDifferent = true;
  }
  if (lastSpindleDirection != tool.clockwise) {
    areDifferent = true;
  }
  if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    var _spindleSpeed = tool.surfaceSpeed * ((unit == MM) ? 1 / 1000.0 : 1 / 12.0);
    if ((lastSpindleMode != SPINDLE_CONSTANT_SURFACE_SPEED) ||
        rpmFormat.areDifferent(lastSpindleSpeed, _spindleSpeed)) {
      areDifferent = true;
    }
  } else {
    if ((lastSpindleMode != SPINDLE_CONSTANT_SPINDLE_SPEED) ||
        rpmFormat.areDifferent(lastSpindleSpeed, spindleSpeed)) {
      areDifferent = true;
    }
  }
  return areDifferent;
}

function onSpindleSpeed(spindleSpeed) {
  var current = getSpindle(TOOL) == SPINDLE_LIVE ? sbOutput.getCurrent() : sOutput.getCurrent();
  if (rpmFormat.areDifferent(spindleSpeed, current) || forceSpindleSpeed) { // avoid redundant output of spindle speed
    startSpindle(false, false);
    forceSpindleSpeed = false;
  }
}

// CUSTOM: emit configured turning-mode entry code (G270 / M109 / none)
function writeTurningModeEntry() {
  var mode = getProperty("turningModeCommand");
  if (mode == "g270") {
    writeBlock(gPlaneModal.format(getCode("ENABLE_TURNING", getSpindle(PART))));
  } else if (mode == "m109") {
    writeBlock(mFormat.format(getCode("DISABLE_C_AXIS", getSpindle(PART))));
  }
  // "none" -> emit nothing
}

function startSpindle(tappingMode, forceRPMMode, initialPosition) {
  var spindleDir;
  var _spindleSpeed;
  var spindleMode;

  gSpindleModeModal.reset();

  if ((getSpindle(PART) == SPINDLE_SUB) && !gotSecondarySpindle) {
    error(localize("Secondary spindle is not available."));
    return;
  }

  // CUSTOM: snapshot whether the relevant spindle is already running *before*
  // we call getCode("START_SPINDLE_*", ...), which flips the corresponding
  // machineState.*SpindleIsActive flag to true as a side effect. Used below
  // to suppress a redundant M03/M04 word when the spindle is already on in
  // the requested direction.
  var __activeSpindle = getSpindle(TOOL);
  var __spindleAlreadyOn = (__activeSpindle == SPINDLE_LIVE) ? machineState.liveToolIsActive :
                           (__activeSpindle == SPINDLE_SUB)  ? machineState.subSpindleIsActive :
                                                               machineState.mainSpindleIsActive;

  if (false /*tappingMode*/) {
    spindleDir = mFormat.format(getCode("RIGID_TAPPING", getSpindle(TOOL)));
  } else {
    spindleDir = mFormat.format(tool.clockwise ? getCode("START_SPINDLE_CW", getSpindle(TOOL)) : getCode("START_SPINDLE_CCW", getSpindle(TOOL)));
  }

  var maximumSpindleSpeed = (tool.maximumSpindleSpeed > 0) ? Math.min(tool.maximumSpindleSpeed, getProperty("maximumSpindleSpeed")) : getProperty("maximumSpindleSpeed");
  if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    _spindleSpeed = tool.surfaceSpeed * ((unit == MM) ? 1 / 1000.0 : 1 / 12.0);
    if (forceRPMMode) { // RPM mode is forced until move to initial position
      if (xFormat.getResultingValue(initialPosition.x) == 0) {
        _spindleSpeed = maximumSpindleSpeed;
      } else {
        _spindleSpeed = Math.min((_spindleSpeed * ((unit == MM) ? 1000.0 : 12.0) / (Math.PI * Math.abs(initialPosition.x * 2))), maximumSpindleSpeed);
      }
      spindleMode = getCode("CONSTANT_SURFACE_SPEED_OFF", getSpindle(TOOL));
    } else {
      spindleMode = getCode("CONSTANT_SURFACE_SPEED_ON", getSpindle(TOOL));
    }
  } else {
    _spindleSpeed = spindleSpeed;
    spindleMode = getCode("CONSTANT_SURFACE_SPEED_OFF", getSpindle(TOOL));
  }

  var scode = getSpindle(TOOL) == SPINDLE_LIVE ? sbOutput.format(_spindleSpeed) : sOutput.format(_spindleSpeed);
  // CUSTOM: optional M41 (low / live tool) / M42 (high / main spindle) gear-range code,
  // suppressed when the gear hasn't actually changed since the last emission.
  var gearCode = "";
  if (getProperty("useGearRanges")) {
    var __newGear = (getSpindle(TOOL) == SPINDLE_LIVE) ? 41 : 42;
    if (__newGear != lastEmittedGear) {
      gearCode = mFormat.format(__newGear);
      lastEmittedGear = __newGear;
    }
  }

  // CUSTOM: suppress the M03/M04 spindle-direction word when the requested
  // spindle was already running in the requested direction (snapshot taken
  // above before getCode flipped the active flag). Avoids redundant M03
  // emissions on every G96/G97 mode swap or speed change within a section.
  if (__spindleAlreadyOn && (lastSpindleDirection === tool.clockwise)) {
    spindleDir = "";
  }

  writeBlock(gSpindleModeModal.format(spindleMode), scode, gearCode, spindleDir);
  // wait for spindle here if required

  lastSpindleMode = tool.getSpindleMode();
  lastSpindleSpeed = _spindleSpeed;
  lastSpindleDirection = tool.clockwise;
}

function onCommand(command) {
  switch (command) {
  case COMMAND_COOLANT_OFF:
    setCoolant(COOLANT_OFF);
    break;
  case COMMAND_COOLANT_ON:
    setCoolant(tool.coolant);
    break;
  case COMMAND_LOCK_MULTI_AXIS:
    writeBlock(cAxisBrakeModal.format(getCode("LOCK_MULTI_AXIS", getSpindle(PART))));
    break;
  case COMMAND_UNLOCK_MULTI_AXIS:
    writeBlock(cAxisBrakeModal.format(getCode("UNLOCK_MULTI_AXIS", getSpindle(PART))));
    break;
  case COMMAND_START_CHIP_TRANSPORT:
    writeBlock(mFormat.format(244));
    break;
  case COMMAND_STOP_CHIP_TRANSPORT:
    writeBlock(mFormat.format(243));
    break;
  case COMMAND_OPEN_DOOR:
    if (gotDoorControl) {
      writeBlock(mFormat.format(208)); // optional
    }
    break;
  case COMMAND_CLOSE_DOOR:
    if (gotDoorControl) {
      writeBlock(mFormat.format(209)); // optional
    }
    break;
  case COMMAND_BREAK_CONTROL:
    break;
  case COMMAND_TOOL_MEASURE:
    break;
  case COMMAND_ACTIVATE_SPEED_FEED_SYNCHRONIZATION:
    break;
  case COMMAND_DEACTIVATE_SPEED_FEED_SYNCHRONIZATION:
    break;
  case COMMAND_STOP:
    writeBlock(mFormat.format(0));
    forceSpindleSpeed = true;
    forceCoolant = true;
    break;
  case COMMAND_OPTIONAL_STOP:
    writeBlock(mFormat.format(1));
    forceSpindleSpeed = true;
    forceCoolant = true;
    break;
  case COMMAND_END:
    writeBlock(mFormat.format(2));
    break;
  case COMMAND_STOP_SPINDLE:
    // CUSTOM: skip M05/M12 when the relevant spindle isn't currently running.
    // The machineState flags are kept up-to-date by getCode("STOP_SPINDLE", ...)
    // / getCode("START_SPINDLE_CW"|"_CCW", ...) so they reflect the last issued
    // start/stop. Keeps the wrap-up cleanly paired without spurious stop codes
    // (e.g. an M12 at the top of a section after the previous section already
    // emitted one).
    var __stopActive = (activeSpindle == SPINDLE_LIVE) ? machineState.liveToolIsActive :
                       (activeSpindle == SPINDLE_SUB)  ? machineState.subSpindleIsActive :
                                                         machineState.mainSpindleIsActive;
    if (!__stopActive) {
      break;
    }
    writeBlock(mFormat.format(getCode("STOP_SPINDLE", activeSpindle)));
    forceSpindleSpeed = true;
    break;
  case COMMAND_ORIENTATE_SPINDLE:
    if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
      writeBlock(mFormat.format(getCode("ORIENT_SPINDLE", getSpindle(PART))));
    } else {
      error(localize("Spindle orientation is not supported for live tooling."));
      return;
    }
    forceSpindleSpeed = true;
    break;
  case COMMAND_START_SPINDLE:
    onCommand(tool.clockwise ? COMMAND_SPINDLE_CLOCKWISE : COMMAND_SPINDLE_COUNTERCLOCKWISE);
    return;
  case COMMAND_SPINDLE_CLOCKWISE:
    writeBlock(mFormat.format(getCode("START_SPINDLE_CW", getSpindle(TOOL))));
    break;
  case COMMAND_SPINDLE_COUNTERCLOCKWISE:
    writeBlock(mFormat.format(getCode("START_SPINDLE_CCW", getSpindle(TOOL))));
    break;
  // case COMMAND_CLAMP: // add support for clamping
  // case COMMAND_UNCLAMP: // add support for clamping
  default:
    onUnsupportedCommand(command);
  }
}

/** Get synchronization/transfer code based on part cutoff spindle direction. */
function getSpindleTransferCodes() {
  var tool = currentSection.getTool();
  var transferCodes = {
    direction          : tool.clockwise ? getCode("START_SPINDLE_CW", getSpindle(PART)) : getCode("START_SPINDLE_CCW", getSpindle(PART)),
    spindleMode        : SPINDLE_CONSTANT_SPINDLE_SPEED,
    surfaceSpeed       : tool.surfaceSpeed,
    maximumSpindleSpeed: tool.maximumSpindleSpeed
  };
  var numberOfSections = getNumberOfSections();
  for (var i = getNextSection().getId(); i < numberOfSections; ++i) {
    var section = getSection(i);
    if (section.getParameter("operation-strategy") == "turningSecondarySpindleReturn" || section.getParameter("operation-strategy") == "turningSecondarySpindlePull") {
      continue;
    } else if (section.getType() != TYPE_TURNING || section.spindle != SPINDLE_MAIN) {
      break;
    } else if (section.getType() == TYPE_TURNING) {
      var tool = section.getTool();
      transferCodes.spindleMode = tool.getSpindleMode();
      transferCodes.surfaceSpeed = tool.surfaceSpeed;
      transferCodes.maximumSpindleSpeed = tool.maximumSpindleSpeed;
      transferCodes.spindleDirection = tool.clockwise;
      break;
    }
  }
  return transferCodes;
}

function getG17Code() {
  return machineState.usePolarInterpolation ? 17 : 17;
}

function ejectPart() {
  writeln("");
  if (getProperty("showSequenceNumbers") == "toolChange") {
    writeCommentSeqno(localize("PART EJECT"));
  } else {
    writeComment(localize("PART EJECT"));
  }
  gMotionModal.reset();
  // writeBlock(gMotionModal.format(0), gFormat.format(28), gFormat.format(53), "B" + abcFormat.format(0)); // retract bar feeder
  writeRetract(X); // Position all axes to home position
  writeRetract(Z);
  writeBlock(mFormat.format(getCode("UNLOCK_MULTI_AXIS", getSpindle(PART))));
  if (!getProperty("optimizeCAxisSelect")) {
    cAxisEngageModal.reset();
  }
  writeBlock(
    gFeedModeModal.format(getCode("FEED_MODE_UNIT_MIN", getSpindle(TOOL))),
    // gFormat.format(53 + currentWorkOffset),
    // gPlaneModal.format(getG17Code()),
    cAxisEngageModal.format(getCode("DISABLE_C_AXIS", getSpindle(PART)))
  );
  // setCoolant(COOLANT_THROUGH_TOOL);
  gSpindleModeModal.reset();
  writeBlock(
    gSpindleModeModal.format(getCode("CONSTANT_SURFACE_SPEED_OFF", getSpindle(PART))),
    sOutput.format(50),
    mFormat.format(getCode("START_SPINDLE_CW", getSpindle(PART)))
  );
  // writeBlock(mFormat.format(getCode("INTERLOCK_BYPASS", getSpindle(PART))));
  if (getProperty("usePartCatcher")) {
    writeBlock(mFormat.format(getCode("PART_CATCHER_ON", getSpindle(PART))));
  }
  writeBlock(mFormat.format(getCode("UNCLAMP_CHUCK", getSpindle(PART))));
  onDwell(1.5);
  // writeBlock(mFormat.format(getCode("CYCLE_PART_EJECTOR")));
  // onDwell(0.5);
  if (getProperty("usePartCatcher")) {
    writeBlock(mFormat.format(getCode("PART_CATCHER_OFF", getSpindle(PART))));
    onDwell(1.1);
  }

  // clean out chips
  /*
  if (airCleanChuck) {
    writeBlock(mFormat.format(getCode("COOLANT_AIR_ON", getSpindle(PART))));
    onDwell(2.5);
    writeBlock(mFormat.format(getCode("COOLANT_AIR_OFF", getSpindle(PART))));
  }
*/
  writeBlock(mFormat.format(getCode("STOP_SPINDLE", getSpindle(PART))));
  // setCoolant(COOLANT_OFF);
  writeComment(localize("END OF PART EJECT"));
  writeln("");
}

function engagePartCatcher(engage) {
  if (getProperty("usePartCatcher")) {
    if (engage) { // engage part catcher
      writeBlock(mFormat.format(getCode("PART_CATCHER_ON", true)), formatComment(localize("PART CATCHER ON")));
    } else { // disengage part catcher
      onCommand(COMMAND_COOLANT_OFF);
      writeBlock(mFormat.format(getCode("PART_CATCHER_OFF", true)), formatComment(localize("PART CATCHER OFF")));
    }
  }
}

function onSectionEnd() {

  // CUSTOM: accumulate the deepest machined Z so the tool-based bar puller can
  // place its grip on unmachined stock without hitting prior features.
  updateMinMachinedZ();

  // CUSTOM: run polar / Y-axis teardown BEFORE the bar-pull prelude (and
  // BEFORE any wrap-up emitted at the top of the next section's onSection)
  // so the cycle's own cleanup codes (G136, etc.) land inside the cycle's
  // section -- ahead of the retract / M01 -- instead of trailing after them.
  if (machineState.usePolarInterpolation) {
    setPolarInterpolation(false); // disable polar interpolation mode
  }

  if (isPolarModeActive()) {
    setPolarCoordinates(false); // disable Polar coordinates mode
  }

  // deactivate Y-axis
  if (gotYAxis && yOutput.isEnabled()) {
    writeBlock(gMotionModal.format(0), yOutput.format(0));
    writeBlock(gPolarModal.format(getCode("DISABLE_Y_AXIS", true)));
    yOutput.disable();
  }

  // CUSTOM: if the next section is a tool-based bar pull, emit the wrap-up
  // (spindle/coolant/retract/optional-stop) here so it visually closes out the
  // current operation instead of being buried inside the bar-pull block.
  // Order matches every other section's wrap-up: stop spindle, coolant off,
  // retract X, retract Z, then optional stop -- home before M1.
  if (getProperty("useToolBarPuller") &&
      !machineState.stockTransferIsActive &&
      ((getCurrentSectionId() + 1) < getNumberOfSections())) {
    var nextSection = getNextSection();
    if (nextSection && nextSection.hasCycle && nextSection.hasCycle("secondary-spindle-pull")) {
      onCommand(COMMAND_STOP_SPINDLE);
      onCommand(COMMAND_COOLANT_OFF);
      writeRetract(X);
      writeRetract(Z);
      onCommand(COMMAND_OPTIONAL_STOP);
      barPullPreludeEmitted = true;
    }
  }

  // cancel SFM mode to preserve spindle speed
  if ((tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) && !machineState.stockTransferIsActive) {
    startSpindle(false, true, getFramePosition(currentSection.getFinalPosition()));
  }

  if (getProperty("usePartCatcher") && partCutoff && currentSection.partCatcher) {
    engagePartCatcher(false);
  }

  if (((getCurrentSectionId() + 1) >= getNumberOfSections()) ||
      (tool.number != getNextSection().getTool().number)) {
    onCommand(COMMAND_BREAK_CONTROL);
  }
  operationNeedsSafeStart = false; // reset for next section

  forcePolarCoordinates = false;
  forcePolarInterpolation = false;
  partCutoff = false;
  forceAny();
  skipThreading = false;
}

function onClose() {

  var liveTool = getSpindle(TOOL) == SPINDLE_LIVE;
  optionalSection = false;
  if (machineState.stockTransferIsActive) {
    writeBlock(mFormat.format(getCode("SPINDLE_SYNCHRONIZATION_OFF", getSpindle(PART))), formatComment("SYNCHRONIZED ROTATION OFF"));
  } else {
    onCommand(COMMAND_STOP_SPINDLE);
    setCoolant(COOLANT_OFF);
  }

  writeln("");

  if (getProperty("gotChipConveyor")) {
    onCommand(COMMAND_STOP_CHIP_TRANSPORT);
  }
  if (machineState.tailstockIsActive) {
    writeBlock(mFormat.format(getCode("TAILSTOCK_OFF", SPINDLE_MAIN)));
  }

  gMotionModal.reset();
  if (gotSecondarySpindle) {
    // writeBlock(gMotionModal.format(0), gFormat.format(28), gFormat.format(53), "B" + abcFormat.format(0)); // retract Sub Spindle if applicable
  }

  // Move to home position
  writeRetract(X);
  writeRetract(Z);

  writeTurningModeEntry(); // CUSTOM: configurable G270 / M109 / none

  // cancel load monitoring
  if (getProperty("loadMonitoring") != 0) {
    writeln("VLMON[" + vlmon + "]=0");
    writeln(mFormat.format(215));
  }

  // Automatically eject part
  if (ejectRoutine) {
    ejectPart();
  }

  writeln("");
  onCommand(COMMAND_OPEN_DOOR);
  writeBlock(mFormat.format(30)); // stop program, spindle stop, coolant off
}
