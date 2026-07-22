unit Gui_Helpers;

{$MODE objfpc}
{$H+}

interface

uses
    Controls;

function SetControlAccessibleName(Control: TWinControl; const AccessibleName: string): Boolean;

implementation

uses
    ActiveX,
    SysUtils,
    Variants,
    Windows;

type
    IAccPropServices = interface(IUnknown)
        ['{6E26E776-04F0-495D-80E4-3330352E3169}']
        function SetPropValue(
            Identity: PByte;
            IdentityLength: DWORD;
            PropertyId: TGUID;
            Value: OleVariant
        ): HRESULT; stdcall;
        function SetPropServer(
            Identity: PByte;
            IdentityLength: DWORD;
            PropertyIds: PGUID;
            PropertyCount: Integer;
            Server: IUnknown;
            AnnotationScope: Integer
        ): HRESULT; stdcall;
        function ClearProps(
            Identity: PByte;
            IdentityLength: DWORD;
            PropertyIds: PGUID;
            PropertyCount: Integer
        ): HRESULT; stdcall;
        function SetHwndProp(
            WindowHandle: HWND;
            ObjectId, ChildId: DWORD;
            PropertyId: TGUID;
            Value: OleVariant
        ): HRESULT; stdcall;
        function SetHwndPropStr(
            WindowHandle: HWND;
            ObjectId, ChildId: DWORD;
            PropertyId: TGUID;
            Value: PWideChar
        ): HRESULT; stdcall;
    end;

const
    CHILDID_SELF = 0;
    CLSID_AccPropServices: TGUID = '{B5F8350B-0548-48B1-A6EE-88BD00B4A5E7}';
    OBJID_CLIENT = DWORD($FFFFFFFC);
    PROPID_ACC_NAME: TGUID = '{608D3DF8-8128-4AA7-A428-F55E49267291}';

function SetControlAccessibleName(Control: TWinControl; const AccessibleName: string): Boolean;
var
    NameAsUnicode: UnicodeString;
    PropertyServices: IAccPropServices;
begin
    Result := False;
    if Control = nil then
        Exit;
    Control.AccessibleName := AccessibleName;
    if Failed(
        CoCreateInstance(CLSID_AccPropServices, nil, CLSCTX_INPROC_SERVER, IAccPropServices, PropertyServices)) then
        Exit;
    NameAsUnicode := UTF8Decode(AccessibleName);
    Result :=
        Succeeded(
            PropertyServices
                .SetHwndPropStr(Control.Handle, OBJID_CLIENT, CHILDID_SELF, PROPID_ACC_NAME, PWideChar(NameAsUnicode))
        );
end;

end.
