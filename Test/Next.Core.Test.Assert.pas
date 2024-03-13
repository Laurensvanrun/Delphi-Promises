unit Next.Core.Test.Assert;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  System.Rtti,
  DUnitX.Assert,
  TestFramework,
  Next.Core.Promises,
  Next.Core.FailureReason,
  Next.Core.TTry;

const
  DATETIMEPART_SEC: Double = 1 / (24 * 60 * 60);
  DATETIMEPART_MSEC: Double = 1 / (24 * 60 * 60 * 1000);

type
  Assert = class(DUnitX.Assert.Assert)
  private
    class procedure CheckExceptionClass(E: Exception; const AExceptionClass: ExceptClass); static;

    class function IsGeneric(const AClassType: TRttiType; const AGenericName: String): Boolean;
    class function GenericGetItemMethod(AType: TRttiType): TRttiMethod;
    class function GenericCountProperty(AType: TRttiType): TRttiProperty;

    class procedure AreEqualCore(const expected, actual: TValue; const AMessage: string = '');
    class procedure AreNotEqualCore(const expected, actual: TValue; const AMessage: string = '');
    class procedure AreEqualLists(const expected, actual : TValue; const AMessage : string = '');
    class procedure AreNotEqualLists(const expected, actual : TValue; const AMessage : string = '');

  public
    class procedure Rejects(APromise: IPromiseAccess);
    class procedure RejectsWith(APromise: IPromiseAccess; AExceptionClass: ExceptClass);
    class procedure RejectsWithMsg(APromise: IPromiseAccess; const AExceptionMessage: String);
    class procedure RejectsWithClassAndMsg(APromise: IPromiseAccess; AExceptionClass: ExceptClass; const AExceptionMessage: String);
    class procedure RejectsWithClassAndMessageContains(APromise: IPromiseAccess; AExceptionClass: ExceptClass; const AMessagePart: String);
    class procedure Resolves(APromise: IPromiseAccess);
    class function ResolvesTo<T>(APromise: IPromise<T>; AValueToCompare: T; const AMessage: string = ''): T; overload;
    class function ResolvesTo<T>(APromise: IPromise<T>): T; overload;
    class procedure AreEqual(const expected, actual: Double; const tolerance : Double; const AMessage : string = ''); overload;
    class procedure AreEqual(const expected, actual: Extended; const tolerance : Double; const AMessage : string = ''); overload;
    class procedure AreEqual<T>(const expected, actual : T; const AMessage : string = ''); overload;
    class procedure AreNotEqual<T>(const expected, actual : T; const AMessage : string = ''); overload;
    class procedure Wait(ASuccessfull: TFunc<Boolean>; ATimeoutInMs: Integer = 10000; const AMessage: String = '');
    class procedure IsBetween(const AMin, AMax: Double; const AActual: Double; const ATolerance: Double; const AMessage: String = '');
  end;

  TAbstractTestHelper = class helper for TAbstractTest
  private
    procedure CheckExceptionClass(E: Exception; const AExceptionClass: ExceptClass);
  public
    procedure CheckEquals<T>(const expected, actual : T; const AMessage : string = '');overload;
    procedure CheckRejects(APromise: IPromiseAccess);
    procedure CheckRejectsWith(APromise: IPromiseAccess; AExceptionClass: ExceptClass);
    procedure CheckResolves(APromise: IPromiseAccess);
  end;

  ETestException = class(Exception);

  TPromiseHelper = class helper for Promise
    class function MockResolve<T>(AValue: T): TValue; overload;
    class function MockResolve<T>(): TValue; overload;
    class function MockReject<T>(AMessage: string = ''): TValue; overload;
    class function MockReject<T>(AException: Exception): TValue; overload;
  end;

  TTryHelper = class helper for TTry
    class function MockSuccess<T>(AValue: T): TValue; overload;
    class function MockSuccess<T>(): TValue; overload;
    class function MockFailure<T>(AMessage: string = ''): TValue; overload;
    class function MockFailure<T>(AException: Exception): TValue; overload;
  end;

implementation

uses
  DUnitX.ResStrs, System.DateUtils, Delphi.Mocks.Helpers, System.TypInfo,
  Spring.Reflection, System.Generics.Defaults, System.Math, System.Types;

{ Assert }

class procedure Assert.AreEqual(const expected, actual: Double; const tolerance: Double; const AMessage: string);
begin
  inherited AreEqual(expected, actual, tolerance, AMessage);
end;

class procedure Assert.AreEqual<T>(const expected, actual: T; const AMessage: string);
begin
  if IsGeneric(TType.GetType(System.TypeInfo(T)), 'TList<>') then
    AreEqualLists(TValue.From<T>(expected), TValue.From<T>(actual), AMessage)
  else
    AreEqualCore(TValue.From<T>(expected), TValue.From<T>(actual), AMessage);
end;

class procedure Assert.AreEqual(const expected, actual: Extended; const tolerance: Double; const AMessage: string);
begin
  inherited AreEqual(expected, actual, tolerance, AMessage);
end;

class procedure Assert.AreEqualCore(const expected, actual: TValue; const AMessage: string);
begin
  DoAssert;
  if not expected.Equals(actual) then
    FailFmt(SNotEqualErrorStr, [expected.ToString, actual.ToString, AMessage], ReturnAddress)
end;

class procedure Assert.AreEqualLists(const expected, actual: TValue; const AMessage: string);
begin
  var LGetCount := GenericCountProperty(expected.RttiType);
  var LGetItem := GenericGetItemMethod(expected.RttiType);

  Assert.AreEqual(LGetCount.GetValue(expected).AsInteger,
    LGetCount.GetValue(actual).AsInteger, AMessage);

  for var i := 0 to LGetCount.GetValue(expected).AsInteger - 1 do
    Assert.AreEqualCore(LGetItem.Invoke(expected, [TValue.From<Integer>(i)]),
      LGetItem.Invoke(actual, [TValue.From<Integer>(i)]), AMessage);
end;

class procedure Assert.AreNotEqual<T>(const expected, actual: T; const AMessage: string);
begin
  if IsGeneric(TType.GetType(System.TypeInfo(T)), 'TList<>') then
    AreNotEqualLists(TValue.From<T>(expected), TValue.From<T>(actual), AMessage)
  else
    AreNotEqualCore(TValue.From<T>(expected), TValue.From<T>(actual), AMessage);
end;

class procedure Assert.AreNotEqualCore(const expected, actual: TValue; const AMessage: string);
begin
  DoAssert;
  if expected.Equals(actual) then
    FailFmt(SEqualsErrorStr2, [expected.ToString, actual.ToString, AMessage], ReturnAddress)
end;

class procedure Assert.AreNotEqualLists(const expected, actual: TValue; const AMessage: string);
begin
  var LGetCount := GenericCountProperty(expected.RttiType);
  var LGetItem := GenericGetItemMethod(expected.RttiType);

  Assert.AreNotEqual(LGetCount.GetValue(expected).AsInteger,
    LGetCount.GetValue(actual).AsInteger, AMessage);

  for var i := 0 to LGetCount.GetValue(expected).AsInteger - 1 do
    Assert.AreNotEqualCore(LGetItem.Invoke(expected, [TValue.From<Integer>(i)]),
      LGetItem.Invoke(actual, [TValue.From<Integer>(i)]), AMessage);
end;

class procedure Assert.CheckExceptionClass(E: Exception; const AExceptionClass: ExceptClass);
begin
  DoAssert;
  if AExceptionClass = nil then
    Exit;

  if E.ClassType <> AExceptionClass then
    FailFmt(SCheckExceptionClassError, [E.ClassName, exceptionClass.ClassName, E.message], ReturnAddress);
end;

class function Assert.GenericCountProperty(AType: TRttiType): TRttiProperty;
begin
  Result := AType.GetProperty('Count');
end;

class function Assert.GenericGetItemMethod(AType: TRttiType): TRttiMethod;
begin
  Result := nil;
  for var LMethod in AType.GetMethods('GetItem') do
    if (LMethod.ParameterCount = 1) and (LMethod.Parameters[0].ParamType.TypeKind = tkInteger)
      and (LMethod.ReturnType = AType.GetGenericArguments[0]) then
      Exit(LMethod);
end;

class procedure Assert.IsBetween(const AMin, AMax, AActual, ATolerance: Double; const AMessage: String);
begin
  if (CompareValue(AMin, AActual, ATolerance) = GreaterThanValue)
  or (CompareValue(AMax, AActual, ATolerance) = LessThanValue) then
    FailFmt('%f not between %f and %f', [AActual, AMin, AMax])
end;

class function Assert.IsGeneric(const AClassType: TRttiType; const AGenericName: String): Boolean;
begin
  Result := AClassType.IsGenericTypeOf(AGenericName);

  if not Result then begin
    var baseType := AClassType.BaseType;
    Result := Assigned(baseType) and IsGeneric(baseType, AGenericName);
  end;
end;

class procedure Assert.Rejects(APromise: IPromiseAccess);
resourcestring
  SNotRejected = 'Promise is not rejected after timeout. %s';
begin
  DoAssert;
  APromise.InternalWait(60000);
  if APromise.State <> psRejected then
    FailFmt(SNotRejected,[TRttiEnumerationType.GetName(APromise.State)], ReturnAddress);
end;

class procedure Assert.RejectsWith(APromise: IPromiseAccess;
  AExceptionClass: ExceptClass);
resourcestring
  SNotRejected = 'Promise is not rejected after timeout. %s';
begin
  DoAssert;
  APromise.InternalWait(60000);
  if APromise.State <> psRejected then
    FailFmt(SNotRejected,[TRttiEnumerationType.GetName(APromise.State)], ReturnAddress);

  CheckExceptionClass(APromise.GetFailure.Reason, AExceptionClass);
end;

class procedure Assert.RejectsWithMsg(APromise: IPromiseAccess; const AExceptionMessage: String);
resourcestring
  SNotRejected = 'Promise is not rejected after timeout. %s';
begin
  DoAssert;
  APromise.InternalWait(60000);
  if APromise.State <> psRejected then
    FailFmt(SNotRejected,[TRttiEnumerationType.GetName(APromise.State)], ReturnAddress);
  Assert.AreEqual(AExceptionMessage, APromise.GetFailure.Reason.Message);
end;

class procedure Assert.RejectsWithClassAndMsg(APromise: IPromiseAccess; AExceptionClass: ExceptClass; const AExceptionMessage: String);
resourcestring
  SNotRejected = 'Promise is not rejected after timeout. %s';
begin
  DoAssert;
  APromise.InternalWait(60000);
  if APromise.State <> psRejected then
    FailFmt(SNotRejected,[TRttiEnumerationType.GetName(APromise.State)], ReturnAddress);

  CheckExceptionClass(APromise.GetFailure.Reason, AExceptionClass);
  Assert.AreEqual(AExceptionMessage, APromise.GetFailure.Reason.Message);
end;

class procedure Assert.RejectsWithClassAndMessageContains(APromise: IPromiseAccess; AExceptionClass: ExceptClass; Const AMessagePart: String);
resourcestring
  SNotRejected = 'Promise is not rejected after timeout. %s';
begin
  DoAssert;
  APromise.InternalWait(60000);
  if APromise.State <> psRejected then
    FailFmt(SNotRejected,[TRttiEnumerationType.GetName(APromise.State)], ReturnAddress);

  CheckExceptionClass(APromise.GetFailure.Reason, AExceptionClass);
  Assert.IsTrue(APromise.GetFailure.Reason.Message.Contains(AMessagePart));
end;

class procedure Assert.Resolves(APromise: IPromiseAccess);
resourcestring
  SRejected = 'Promise is not resolved after timeout. %s (%s)';
  SPending = 'Promise is not resolved after timeout. %s';
begin
  DoAssert;
  APromise.InternalWait(60000);
  if APromise.State = psRejected then
    FailFmt(SRejected,[TRttiEnumerationType.GetName(APromise.State), APromise.GetFailure.Reason.Message], ReturnAddress);
  if APromise.State = psPending then
    FailFmt(SPending,[TRttiEnumerationType.GetName(APromise.State)], ReturnAddress);
end;

class function Assert.ResolvesTo<T>(APromise: IPromise<T>;  AValueToCompare: T; const AMessage: string): T;
begin
  Result := ResolvesTo<T>(APromise);
  Assert.AreEqual<T>(AValueToCompare, Result);
end;

class function Assert.ResolvesTo<T>(APromise: IPromise<T>): T;
begin
  Resolves(APromise);
  Result := APromise.Await;
end;

class procedure Assert.Wait(ASuccessfull: TFunc<Boolean>; ATimeoutInMs: Integer = 10000; const AMessage: String = '');
resourcestring
  STimedout = 'Test timeout before finished. %s';
begin
  while (Now < IncMilliSecond(Now, ATimeoutInMs)) do begin
    if ASuccessfull() then
      Exit;
	Sleep(10);
  end;
  FailFmt(SUnexpectedErrorStr ,[AMessage], ReturnAddress);
end;

{ TAbstractTestHelper }

procedure TAbstractTestHelper.CheckEquals<T>(const expected, actual: T; const AMessage: string);
begin
  Assert.AreEqual<T>(expected, actual, AMessage);
end;

procedure TAbstractTestHelper.CheckExceptionClass(E: Exception;
  const AExceptionClass: ExceptClass);
begin
  if AExceptionClass = nil then
    Exit;

  if E.ClassType <> AExceptionClass then
    Fail(Format(SCheckExceptionClassError, [E.ClassName, exceptionClass.ClassName, E.message]));
end;

procedure TAbstractTestHelper.CheckRejects(APromise: IPromiseAccess);
resourcestring
  SNotRejected = 'Promise is not rejected. %s';
begin
  FCheckCalled := True;
  APromise.InternalWait;
  if APromise.State <> psRejected then
    Fail(Format(SNotRejected,[TRttiEnumerationType.GetName(APromise.State)]));
end;

procedure TAbstractTestHelper.CheckRejectsWith(APromise: IPromiseAccess;
  AExceptionClass: ExceptClass);
resourcestring
  SNotRejected = 'Promise is not rejected. %s';
begin
  FCheckCalled := True;
  APromise.InternalWait;
  if APromise.State <> psRejected then
    Fail(Format(SNotRejected,[TRttiEnumerationType.GetName(APromise.State)]));

  CheckExceptionClass(APromise.GetFailure.Reason, AExceptionClass);
end;

procedure TAbstractTestHelper.CheckResolves(APromise: IPromiseAccess);
resourcestring
  SNotResolved = 'Promise is not resolved. %s (%s)';
begin
  FCheckCalled := True;
  APromise.InternalWait;
  if APromise.State <> psFullfilled then
    Fail(Format(SNotResolved,[TRttiEnumerationType.GetName(APromise.State), APromise.GetFailure.Reason.Message]));
end;

{ TPromiseHelper }

class function TPromiseHelper.MockReject<T>(AMessage: string = ''): TValue;
begin
  Result := TValue.From<IPromise<T>>(Promise.Reject<T>(ETestException.Create(AMessage)));
end;

class function TPromiseHelper.MockReject<T>(AException: Exception): TValue;
begin
  Result := TValue.From<IPromise<T>>(Promise.Reject<T>(AException));
end;

class function TPromiseHelper.MockResolve<T>: TValue;
begin
  Result := TValue.From<IPromise<T>>(Promise.Resolve<T>(function: T begin Result := Default(T) end));
end;

class function TPromiseHelper.MockResolve<T>(AValue: T): TValue;
begin
  Result := TValue.From<IPromise<T>>(Promise.Resolve<T>(function: T begin Result := AValue end));
end;

{ TTryHelper }

class function TTryHelper.MockFailure<T>(AException: Exception): TValue;
begin
  Result := TValue.From<ITry<T>>(TFailure<T>.Create(TFailureReason.Create(AException)));
end;

class function TTryHelper.MockFailure<T>(AMessage: string): TValue;
begin
  Result := TValue.From<ITry<T>>(TFailure<T>.Create(TFailureReason.Create(ETestException.Create(AMessage))));
end;

class function TTryHelper.MockSuccess<T>: TValue;
begin
  Result := TValue.From<ITry<T>>(TSuccess<T>.Create(Default(T)));
end;

class function TTryHelper.MockSuccess<T>(AValue: T): TValue;
begin
  Result := TValue.From<ITry<T>>(TSuccess<T>.Create(AValue));
end;

end.
