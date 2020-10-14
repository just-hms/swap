#include VA.ahk
global Devices := {}
global Count := 0
global supEnumerator 
;gui shit
Gui, +ToolWindow
Gui, Margin, 30, 15
Gui, Font, cDDDDDD s10.5
Gui, Color, 212121
GuiWidth := 320, GuiHeight := 50
Gui, Add, Text,vVar w%GuiWidth%,0
Gui, Margin, 5, 15
Gui, -Caption +LastFound +border ;+AlwaysOnTop
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

GetDeviceID()
{
    tmp:= VA_GetDeviceName(VA_GetDevice("playback"))
    n:=0
    For DeviceName, DeviceID in Devices{
            If (n > 0){
                n+=1
                Return DeviceID
            }
            If (DeviceName = tmp)
                n+=1
    }
    if(tmp > 1)
        For DeviceName, DeviceID in Devices
                Return DeviceID
}

;change sound output                            Win + < 
#<:: 
{
    load()
    SetDefaultEndpoint(GetDeviceID())
    tmp:= VA_GetDeviceName(VA_GetDevice("playback"))
    ;gui shit
    GuiControl,,Var,%tmp%
    Gui,show, % "x" A_ScreenWidth - GuiWidth  " y"  A_ScreenHeight - GuiHeight - 30 " w" Guiwidth " h" GuiHeight
    SetTimer, off, 800
    Return
}


off:
Gui,Hide
Return
