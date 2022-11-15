#SingleInstance, force

#include lib\VA.ahk
global Devices := {}
global Count := 0
global supEnumerator
global curDevice

global showed:=False
global toggled:=True

global configFile:= "lib\swap.config"

;gui shit
Gui, +ToolWindow
Gui, Margin, 0, 10
Gui, Font, c767676 s13
Gui, Color, 191919 ;212121
GuiWidth := 400, GuiHeight := 50
TextWidth:= GuiWidth - 80
ArrowX:= GuiWidth - 25
Gui, -Caption +LastFound ;+border ;+AlwaysOnTop

;add text
Gui, Add, Picture, gA2 vTon x10 y10 w30 h30, lib\images\toggle_on.png
Gui, Add, Picture, gA2 vToff x10 y10 w30 h30, lib\images\toggle_off.png
Gui, Add, Picture, vVolume y10 x10 w30 h30, lib\images\volume.png
Gui, Add, Text ,x50 y14 vVar  w%TextWidth%, 0
Gui, Add, Picture, vAown gHideToggles x%ArrowX% y17 w16 h16, lib\images\down.png
Gui, Add, Picture, vAight gShowToggles x%ArrowX% y17 w16 h16, lib\images\right.png
GuiControl, Hide, Aown
GuiControl, Hide, Ton
GuiControl, Hide, Toff

;WinSet, Region, 0-0 w%GuiWidth% h%GuiHeight% R10-10
DllCall("SetClassLong", "uint", WinExist(), "int", -26, "int", DllCall("GetClassLong", "uint", WinExist(), "int", -26) | 0x20000)
Return

; supEnumerator::EnumAudioEndpoints
; eRender = 0, eCapture, eAll
; 0x1 = DEVICE_STATE_ACTIVE
load()
{
    Devices := {}
    Count := 0
    supEnumerator := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
    DllCall(NumGet(NumGet(supEnumerator+0)+3*A_PtrSize), "UPtr", supEnumerator, "UInt", 0, "UInt", 0x1, "UPtrP", IMMDeviceCollection, "UInt")
    ObjRelease(supEnumerator)
    ; IMMDeviceCollection::GetCount
    DllCall(NumGet(NumGet(IMMDeviceCollection+0)+3*A_PtrSize), "UPtr", IMMDeviceCollection, "UIntP", Count, "UInt")
    Loop % (Count)
    {
        ; IMMDeviceCollection::Item
        DllCall(NumGet(NumGet(IMMDeviceCollection+0)+4*A_PtrSize), "UPtr", IMMDeviceCollection, "UInt", A_Index-1, "UPtrP", IMMDevice, "UInt")
        ; IMMDevice::GetId
        DllCall(NumGet(NumGet(IMMDevice+0)+5*A_PtrSize), "UPtr", IMMDevice, "UPtrP", pBuffer, "UInt")
        DeviceID := StrGet(pBuffer, "UTF-16"), DllCall("Ole32.dll\CoTaskMemFree", "UPtr", pBuffer)
        ; IMMDevice::OpenPropertyStore
        ; 0x0 = STGM_READ
        DllCall(NumGet(NumGet(IMMDevice+0)+4*A_PtrSize), "UPtr", IMMDevice, "UInt", 0x0, "UPtrP", IPropertyStore, "UInt")
        ObjRelease(IMMDevice)
        ; IPropertyStore::GetValue
        VarSetCapacity(PROPVARIANT, A_PtrSize == 4 ? 16 : 24)
        VarSetCapacity(PROPERTYKEY, 20)
        DllCall("Ole32.dll\CLSIDFromString", "Str", "{A45C254E-DF1C-4EFD-8020-67D146A850E0}", "UPtr", &PROPERTYKEY)
        NumPut(14, &PROPERTYKEY + 16, "UInt")
        DllCall(NumGet(NumGet(IPropertyStore+0)+5*A_PtrSize), "UPtr", IPropertyStore, "UPtr", &PROPERTYKEY, "UPtr", &PROPVARIANT, "UInt")
        DeviceName := StrGet(NumGet(&PROPVARIANT + 8), "UTF-16")    ; LPWSTR PROPVARIANT.pwszVal
        DllCall("Ole32.dll\CoTaskMemFree", "UPtr", NumGet(&PROPVARIANT + 8))    ; LPWSTR PROPVARIANT.pwszVal
        ObjRelease(IPropertyStore)
        ObjRawSet(Devices, DeviceName, DeviceID)
        }
    ObjRelease(IMMDeviceCollection)
    Return
}
SetDefaultEndpoint(DeviceID)
{
    IPolicyConfig := ComObjCreate("{870af99c-171d-4f9e-af0d-e63df40c2bc9}", "{F8679F50-850A-41CF-9C72-430F290290C8}")
    DllCall(NumGet(NumGet(IPolicyConfig+0)+13*A_PtrSize), "UPtr", IPolicyConfig, "UPtr", &DeviceID, "UInt", 0, "UInt")
    ObjRelease(IPolicyConfig)
}

GetDeviceID(skips)
{
    tmp:=VA_GetDeviceName(VA_GetDevice("playback"))
    n:=0
    while (skips >= -1){
        For DeviceName, DeviceID in Devices{
            If (n > 0){
                if(n > skips)
                    Return, {Id: DeviceID, Name: DeviceName}
                skips-=1
            }
            If (DeviceName = tmp){
                n+=1
                if (skips = -1)
                    Return, {Id: DeviceID, Name: DeviceName}
            }
                
        }
    }
}   

;change sound output                            Win + <
#<::
    load()
    curDev:= GetDeviceID(-1)
    nextDev:= GetDeviceID(0)
    curDevice:= curDev.Name
    if !showed
    {
        ;i iterate until i find someone that is toggled
        firstk:= NextDev.Name
        k:=1
        while !toggled(NextDev.Name)
        {
            nextDev:= GetDeviceID(k)
            tmp:= NextDev.Name
            ; se faccio un giro completo e non trovo nulla esco    
            if firstk = %tmp%
            {
                nextDev:=curDev
                Break
            }
            k+=1
        }
    }
    ;end shit
    tmp:= NextDev.Name
    if curDevice != %tmp%
        SetDefaultEndpoint(nextDev.Id)
    curDevice:= NextDev.Name
    if showed
        SetToggles()
    GuiControl,,Var, %curDevice%
    Gui,show, % "x" A_ScreenWidth/2 - GuiWidth/2  " y"  A_ScreenHeight/2 - GuiHeight " w" Guiwidth " h" GuiHeight
    SetTimer, off, 800
    Return

ShowToggles:
    GuiControl, Hide, Volume
    SetToggles()
    Return

SetToggles(){
    GuiControl, Hide, Ton
    GuiControl, Hide, Toff
    If toggled(curDevice)
        GuiControl, Show, Ton
    Else
        GuiControl, Show, Toff
    GuiControl, Hide, Aight
    GuiControl, Show, Aown
    showed:= True
    Return
}

HideToggles:
    GuiControl, Hide, Ton
    GuiControl, Hide, Toff
    GuiControl, Hide, Aown
    GuiControl, Show, Aight
    GuiControl, Show, Volume
    showed:= False
    If !toggled(curDevice)
        Send,#<
    Return

; scrive nel file ma non so se va a capo
; deve refreshare il toggle subito ma non lo fa
; poi cicla anche trai dispositivi togglati

A2:
    curDev:= GetDeviceID(-1)
    toggle(curDev.Name)
    return

off:
if !showed
    Gui,Hide
Return

toggled(deviceName){
    FileRead, OutputVar, %configFile%
    StringReplace, newVar, OutputVar, %deviceName%, "differentcharacters" , All
    Return !(OutputVar != newVar)
}

toggle(deviceName){
    FileRead, OutputVar, %configFile%
    StringReplace, newVar, OutputVar, %deviceName%, , All
    if (OutputVar != newVar){
        FileDelete, %configFile%
        FileAppend, %newVar%, %configFile%
    }
    Else{
        FileAppend, %deviceName%, %configFile%
    }
}