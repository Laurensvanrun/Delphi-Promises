unit Next.Core.DisposableValue;

interface

uses
  System.SysUtils;

type
  EDisposableValueException = class(Exception);

  TDisposableValue<T> = record
  private
    FValue: T;
    FHasValue: IInterface;

    function HasValue: Boolean;
    function ObjectInArray<T2>(const AObject: TObject; const AArray: T2): Boolean;

    procedure DisposeP(var Obj);
    procedure &NilP(var Obj);
    procedure DisposeArray;
    procedure TryDisposeArray<T2>(const AOther: T2);
    procedure TryDisposeObject<T2>(const AOther: T2);
  public
    class operator Implicit(const v: T): TDisposableValue<T>;
    class operator Implicit(const dv: TDisposableValue<T>): T;

    procedure TryDispose<T2>(const AOther: T2);
    procedure Dispose;
    procedure &Nil;
  end;

procedure SetFlagInterface(var Intf: IInterface);

implementation

uses
  System.Rtti, Winapi.Windows, Spring.Reflection;

function NopAddref(inst: Pointer): Integer; stdcall;
begin
  Result := -1;
end;

function NopRelease(inst: Pointer): Integer; stdcall;
begin
  Result := -1;
end;

function NopQueryInterface(inst: Pointer; const IID: TGUID; out Obj): HResult; stdcall;
begin
  Result := E_NOINTERFACE;
end;

const
  FlagInterfaceVTable: array[0..2] of Pointer =
  (
    @NopQueryInterface,
    @NopAddref,
    @NopRelease
  );

  FlagInterfaceInstance: Pointer = @FlagInterfaceVTable;

procedure SetFlagInterface(var Intf: IInterface);
begin
  Intf := IInterface(@FlagInterfaceInstance);
end;

{ TDisposableValue<T> }

class operator TDisposableValue<T>.Implicit(const dv: TDisposableValue<T>): T;
begin
  if not dv.HasValue() then
    raise EDisposableValueException.Create('DisposableValue<' + TType.GetType(System.TypeInfo(T)).Name + '> has no value set');

  Result := dv.FValue;
end;

procedure TDisposableValue<T>.DisposeArray;
var
  LValue, LArrayElement: TValue;
  i: Integer;
  LObject: TObject;
begin
  if HasValue() then begin
    LValue := TValue.From<T>(FValue);
    for i := 0 to LValue.GetArrayLength - 1 do begin
      LArrayElement := LValue.GetArrayElement(i);
      if LArrayElement.Kind = tkClass then begin
        LObject := LArrayElement.AsObject;
        DisposeP(LObject);
        LValue.SetArrayElement(i, nil);
      end;
    end;
  end;
end;

procedure TDisposableValue<T>.DisposeP(var Obj);
var
  Temp: TObject;
begin
  if HasValue() then begin
    Temp := TObject(Obj);
    Pointer(Obj) := nil;
    if Assigned(Temp) then
      Temp.Free;
  end;
end;

procedure TDisposableValue<T>.&NilP(var Obj);
begin
  case GetTypeKind(T) of
    tkClass: Pointer(Obj) := nil;
    tkDynArray: FHasValue := nil;
  end;
end;

procedure TDisposableValue<T>.&Nil;
begin
  &NilP(FValue);
end;

procedure TDisposableValue<T>.Dispose;
begin
  case GetTypeKind(T) of
    tkClass: DisposeP(FValue);
    tkDynArray: DisposeArray;
  end;
end;

function TDisposableValue<T>.HasValue: Boolean;
begin
  Result := FHasValue <> nil;
end;

procedure TDisposableValue<T>.TryDispose<T2>(const AOther: T2);
begin
  case GetTypeKind(T) of
    tkClass: TryDisposeObject<T2>(AOther);
    tkDynArray: TryDisposeArray<T2>(AOther);
  end;
end;

procedure TDisposableValue<T>.TryDisposeArray<T2>(const AOther: T2);
type
  PObject = ^TObject;
begin
  var LValue := TValue.From<T>(FValue);

  for var i := 0 to LValue.GetArrayLength - 1 do begin
    var LArrayElement := LValue.GetArrayElement(i);

    if LArrayElement.Kind = tkClass then begin
      var LObject := LArrayElement.AsObject;

      case GetTypeKind(T2) of

        tkClass:
          if PObject(@LObject)^ = PObject(@AOther)^ then
            Continue;

        tkArray, tkDynArray:
          if ObjectInArray(LObject, AOther) then
            Continue;
      end;

      DisposeP(LObject);
      LValue.SetArrayElement(i, nil);
    end;
  end;
end;

procedure TDisposableValue<T>.TryDisposeObject<T2>(const AOther: T2);
type
  PObject = ^TObject;
  PIntf = ^IInterface;
begin
  if (GetTypeKind(T2) = tkInterface) then begin
    var LIntf := (PIntf(@AOther)^ as IInterface);
    var LObj := LIntf as TObject;
    if (PObject(@FValue)^ <> PObject(@LObj)^) then
      DisposeP(FValue)
    else
      NilP(FValue);
  end else if (PObject(@FValue)^ <> PObject(@AOther)^) then
    DisposeP(FValue);
end;

function TDisposableValue<T>.ObjectInArray<T2>(const AObject: TObject; const AArray: T2): Boolean;
begin
  Result := False;

  var LArray := TValue.From<T2>(AArray);
  for var j := 0 to LArray.GetArrayLength - 1 do begin

    var LArrayElement := LArray.GetArrayElement(j);
    if (LArrayElement.Kind = tkClass) then

      if LArray.GetArrayElement(j).AsObject = AObject then
        Exit(True);
  end;
end;

class operator TDisposableValue<T>.Implicit(const v: T): TDisposableValue<T>;
begin
  Result.FValue := v;
  SetFlagInterface(Result.FHasValue);
end;

end.