unit Next.Core.Test.GenericTest;

interface

uses
  DUnitX.TestFramework, System.Generics.Defaults, System.Generics.Collections,
  System.TypInfo;

type
  [TestFixture]
  TGenericTest<T> = class(TObject)
  private
    FTypeInfo: PTypeInfo;
    FTypeData: PTypeData;

    procedure TestEquals(const AExpected, AActual: T; const AFreeExpected, AFreeActual: Boolean);
  protected
    function CreateInstance(const AValue: Integer): TObject; virtual;
    function CreateValue(const AValue: Integer): T;
    procedure ReleaseValue(const AValue: T);

    procedure TestEqualsFreeExpected(const AExpected, AActual: T);
    procedure TestEqualsFreeBoth(const AExpected, AActual: T);
  public
    [Setup]
    procedure Setup; virtual;
  end;

  TSimpleRecord = record
    A, B, C, D: Integer;
  end;

implementation

uses
  System.SysUtils, System.Rtti, Next.Core.Test.Assert, Delphi.Mocks.Helpers;

{ TGenericTest<T> }

function TGenericTest<T>.CreateInstance(const AValue: Integer): TObject;
var
  LValue: TValue;
  ctx: TRttiContext;
  rType: TRttiType;
  AMethCreate: TRttiMethod;
  instanceType: TRttiInstanceType;
begin
  ctx := TRttiContext.Create;
  rType := ctx.GetType(TypeInfo(T));
  for AMethCreate in rType.GetMethods do
  begin
    if (AMethCreate.IsConstructor) then
    begin
      instanceType := rType.AsInstance;
      if (Length(AMethCreate.GetParameters) = 1) and (AMethCreate.GetParameters[0].ParamType.TypeKind = tkInteger) then
      begin
        LValue := AMethCreate.Invoke(instanceType.MetaclassType, [AValue]);
        Result := LValue.AsType<TObject>;
        Exit;
      end else if (Length(AMethCreate.GetParameters) = 0) then begin
        LValue := AMethCreate.Invoke(instanceType.MetaclassType, []);
        Result := LValue.AsType<TObject>;
        Exit;
      end;
    end;
  end;
end;

function TGenericTest<T>.CreateValue(const AValue: Integer): T;
var
  I1: Int8 absolute Result;
  U1: UInt8 absolute Result;
  I2: Int16 absolute Result;
  U2: UInt16 absolute Result;
  I4: Int32 absolute Result;
  U4: UInt32 absolute Result;
  I8: Int64 absolute Result;
  R4: Single absolute Result;
  R8: Double absolute Result;
  R10: Extended absolute Result;
  RI8: Comp absolute Result;
  RC8: Currency absolute Result;
  Obj: TObject absolute Result;
  Cls: TClass absolute Result;
  Intf: IInterface absolute Result;
  Ptr: Pointer absolute Result;
  Proc: TProcedure absolute Result;
  Method: TMethod absolute Result;
  UnicodeStr: UnicodeString absolute Result;
  V: Variant absolute Result;
  Bytes: TBytes absolute Result;
  WC: WideChar absolute Result;
  {$IFNDEF NEXTGEN}
  StrN: ShortString absolute Result;
  AnsiStr: AnsiString absolute Result;
  WideStr: WideString absolute Result;
  AC: AnsiChar absolute Result;
  {$ENDIF}
  SR: TSimpleRecord absolute Result;
begin
  case FTypeInfo.Kind of
    tkInteger,
    tkEnumeration:
      begin
        case FTypeData.OrdType of
          otSByte: I1 := Int8(AValue);
          otUByte: U1 := UInt8(AValue);
          otSWord: I2 := Int16(AValue);
          otUWord: U2 := UInt16(AValue);
          otSLong: I4 := AValue;
          otULong: U4 := UInt32(AValue);
        else
          System.Assert(False);
        end;
      end;

    tkFloat:
      begin
        case FTypeData.FloatType of
          ftSingle  : R4 := AValue;
          ftDouble  : R8 := AValue;
          ftExtended: R10 := AValue;
          ftComp    : RI8 := AValue;
          ftCurr    : RC8 := AValue;
        else
          System.Assert(False);
        end;
      end;

    tkClass:
//      begin
//        System.Assert(TypeInfo(T) = TypeInfo(TFoo));
//        Obj := TFoo.Create(AValue);
//      end;
//System.Assert(False);
//      Obj := T.Create;
      Obj := CreateInstance(AValue);
//
    tkClassRef:
//      Cls := TFoo;
      System.Assert(False);
//
    tkInterface:
//      Intf := TBaz.Create(AValue);
      System.Assert(False);

    tkPointer:
      Ptr := Pointer(AValue);

    tkProcedure:
      Proc := Pointer(AValue);

    tkMethod:
      begin
        Method.Code := Pointer(AValue shr 4);
        Method.Data := Pointer(AValue and $0F);
      end;

    {$IFNDEF NEXTGEN}
    tkString:
//      case SizeOf(T) of
//        2: begin Str1[0] := #1; Str1[1] := AnsiChar(AValue); end;
//        3: begin Str2[0] := #2; Str2[1] := AnsiChar(AValue); Str2[2] := AnsiChar(AValue shr 8) end;
//        4: begin Str3[0] := #3; Str3[1] := AnsiChar(AValue); Str3[2] := AnsiChar(AValue shr 8); Str3[3] := AnsiChar(AValue shr 16) end;
//      else
        StrN := ShortString(IntToStr(AValue));
//      end;

    tkLString:
      AnsiStr := AnsiString(IntToStr(AValue));

    tkWString:
      WideStr := WideString(IntToStr(AValue));
    {$ENDIF}

    tkUString:
      UnicodeStr := UnicodeString(IntToStr(AValue));

    tkVariant:
      V := AValue;

    tkInt64:
      I8 := AValue;

    tkDynArray:
//      case FTypeData.DynArrElType^^.Kind of
//        tkInteger:
//          begin
//            SetLength(Bytes, 2);
//            Bytes[0] := AValue;
//            Bytes[1] := AValue * 2;
//          end;
//
//        tkUString:
//          begin
//            SetLength(MA, 2);
//            MA[0] := UnicodeString(IntToStr(AValue));
//            MA[1] := UnicodeString(IntToStr(AValue * 2));
//          end;
//
//        tkRecord:
//          begin
//            SetLength(FBA, 2);
//            FBA[0].Foo := TFoo.Create(AValue);
//            FBA[0].Bar := TBar.Create(AValue * 2);
//            FBA[0].Foo.Bar := FBA[0].Bar;
//            FBA[0].Bar.Foo := FBA[0].Foo;
//
//            FBA[1].Foo := TFoo.Create(AValue * 3);
//            FBA[1].Bar := TBar.Create(AValue * 4);
//            FBA[1].Foo.Bar := FBA[1].Bar;
//            FBA[1].Bar.Foo := FBA[1].Foo;
//          end
//      else
        System.Assert(False);
//      end;

    {$IFNDEF NEXTGEN}
    tkChar:
      AC := AnsiChar(AValue);
    {$ENDIF}

    tkWChar:
      WC := Char(AValue);

    tkSet:
      begin
        case SizeOf(T) of
          1: U1 := AValue;
          2: U2 := AValue;
          4: U4 := AValue;
        else
          System.Assert(False);
        end;
      end;

//    tkArray:
//      begin
//        Arr[0] := AValue;
//        Arr[1] := AValue * 2;
//        Arr[2] := AValue * 3;
//      end;
//
    tkRecord:
      begin
        if (FTypeInfo.NameFld.ToString = 'TSimpleRecord') then
        begin
          SR.A := AValue;
          SR.B := AValue;
          SR.C := AValue;
          SR.D := AValue;
        end
//        else if (FTypeInfo.NameFld.ToString = 'TManagedRecord') then
//        begin
//          MR.A := AValue;
//          SetLength(MR.B, 1);
//          MR.B[0] := Byte(AValue);
//          MR.C := IntToStr(AValue);
//        end
//        else if (FTypeInfo.NameFld.ToString = 'TFooBarRecord') then
//        begin
//          Foo := TFoo.Create(AValue);
//          Bar := TBar.Create(AValue * 2);
//
//          { Create circular reference }
//          Foo.Bar := Bar;
//          Bar.Foo := Foo;
//          FB.Foo := Foo;
//          FB.Bar := Bar;
//        end
        else
          System.Assert(False);
      end;
  else
    System.Assert(False);
  end;
end;

procedure TGenericTest<T>.ReleaseValue(const AValue: T);
var
  Obj: TObject absolute AValue;
//  FB: TFooBarRecord absolute AValue;
//  FBA: TFooBarArray absolute AValue;
  I: Integer;
begin
  case FTypeInfo.Kind of
    tkClass:
      Obj.DisposeOf;

    tkRecord: ;
//      if (FTypeInfo.NameFld.ToString = 'TFooBarRecord') then
//      begin
//        FB.Foo.DisposeOf;
//        FB.Bar.DisposeOf;
//      end;

    tkDynArray: ;
//      begin
//        if (FTypeData.DynArrElType^^.Kind = tkRecord) then
//        begin
//          for I := 0 to Length(FBA) - 1 do
//          begin
//            FBA[I].Foo.Free;
//            FBA[I].Bar.Free;
//          end;
//        end;
//      end;
  end;
end;

procedure TGenericTest<T>.Setup;
begin
  FTypeInfo := System.TypeInfo(T);
  System.Assert(Assigned(FTypeInfo));
  FTypeData := GetTypeData(FTypeInfo);
  System.Assert(Assigned(FTypeData));
end;

procedure TGenericTest<T>.TestEquals(const AExpected, AActual: T; const AFreeExpected, AFreeActual: Boolean);
begin
  try
    if not SameValue(TValue.From<T>(AExpected), TValue.From<T>(AActual)) then
        Assert.Fail('Values not equal');
  finally
    if GetTypeKind(T) = tkClass then begin
      if AFreeExpected then
        TValue.From<T>(AExpected).AsObject.Free;
      if AFreeActual then
        TValue.From<T>(AActual).AsObject.Free;
    end;
  end;
end;

procedure TGenericTest<T>.TestEqualsFreeBoth(const AExpected, AActual: T);
begin
  TestEquals(AExpected, AActual, True, True);
end;

procedure TGenericTest<T>.TestEqualsFreeExpected(const AExpected, AActual: T);
begin
  TestEquals(AExpected, AActual, True, False);
end;

end.
