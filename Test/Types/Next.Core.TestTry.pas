unit Next.Core.TestTry;

interface

uses
  DUnitX.TestFramework, Next.Core.Test.GenericTest, Next.Core.TTry;

type
  [TestFixture]
  TTestTry<T> = class(TGenericTest<T>)
  private
    FOk: ITry<T>;
    FFails: ITry<T>;
  public
    [Setup]
    procedure Setup; override;
    [Test]
    procedure IsSuccess();
    [Test]
    procedure IsFailure();
    [Test]
    procedure TryOfSuccess();
    [Test]
    procedure TryOfFailure();
    [Test]
    procedure SuccessGetValue();
    [Test]
    procedure SuccessRaiseExceptionIf();
    [Test]
    procedure FailureShouldRaiseOnGetValue();
     [Test]
    procedure FailureRaiseExceptionIfShouldRaise();
    [Test]
    procedure FailureMapReturnsFailure();
    [Test]
    procedure FailureMapTryReturnsFailure();
    [Test]
    procedure SuccessMapReturnSuccess();
    [Test]
    procedure SuccessMapReturnFailure();
    [Test]
    procedure SuccessMapTryReturnSuccess();
    [Test]
    procedure SuccessMapTryReturnFailure();
    [Test]
    procedure SuccessMapReturnSameValue();
    [Test]
    procedure SuccessRecoverDoesNothing();
    [Test]
    procedure SuccessRecoverTryDoesNothing();
    [Test]
    procedure FailureRecoverWorks();
    [Test]
    procedure FailureRecoverTryWorks();
    [Test]
    procedure SuccessTryOp();
    [Test]
    procedure FailureTryOp();
    [Test]
    procedure ResolveOk();
    [Test]
    procedure ResolveFail();
    [Test]
    procedure TryOfOk();
    [Test]
    procedure TryOfFail();
    [Test]
    procedure AssignToOk();
    [Test]
    procedure AssignToFail();
    [Test]
    procedure FailOnOkIsNotCalled();
    [Test]
    procedure FailOnFailIsCalled();
  end;

  TMyObject = class
    FValue: Integer;
  public
    constructor Create(AValue: Integer);
    function Equals(AItem: TObject): Boolean; override;
  end;

  [TestFixture]
  TTestTryOnObject = class
  private
    FOk: ITry<TMyObject>;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure SuccessTryOp();
    [Test]
    procedure SuccessTryOpMapTry();
    [Test]
    procedure TryOpToListKeep();
    [Test]
    procedure AcceptKeepsValue();
  end;

implementation

uses
  Next.Core.Test.Assert, System.SysUtils, System.Rtti,
  System.Generics.Collections;

{ TTestTry<T> }

procedure TTestTry<T>.AssignToFail;
var
  LAssignCalled: Boolean;
begin
  LAssignCalled := False;
  Assert.IsTrue(FFails.AssignTo(procedure(V: T) begin
      LAssignCalled := True;
    end).IsFailure);

  Assert.IsFalse(LAssignCalled);
end;

procedure TTestTry<T>.AssignToOk;
var
  LValue: T;
begin
  Assert.IsTrue(FOk.AssignTo(procedure(V: T) begin
      LValue := V;
    end).IsSuccess);

  TestEqualsFreeBoth(CreateValue(1), LValue);
end;

procedure TTestTry<T>.FailOnFailIsCalled;
begin
  Assert.IsTrue(FFails.Fail(procedure(E: Exception) begin
      Assert.IsTrue(E is ETestException);
    end).IsFailure);
end;

procedure TTestTry<T>.FailOnOkIsNotCalled;
var
  LFailCalled: Boolean;
begin
  LFailCalled := False;
  Assert.IsTrue(FOk.Fail(procedure(E: Exception) begin
      LFailCalled := True;
    end).IsSuccess);
  Assert.IsFalse(LFailCalled);
end;

procedure TTestTry<T>.FailureMapReturnsFailure;
begin
  Assert.IsTrue(FFails.Map(function(V: T): T begin Result := V end).IsFailure);
end;

procedure TTestTry<T>.FailureMapTryReturnsFailure;
begin
  Assert.IsTrue(FFails.Map(
      function(V: T): ITry<T>
      begin
        Result := TTry.Of<T>(function: T
          begin
            Result := CreateValue(2);
          end)
      end).IsFailure);
end;

procedure TTestTry<T>.FailureRecoverTryWorks;
begin
  TestEqualsFreeBoth(CreateValue(2), FFails.Recover(function(E: Exception): ITry<T> begin Result := TTry.Of<T>(function: T begin Result := CreateValue(2); end) end).Value);
end;

procedure TTestTry<T>.FailureRecoverWorks;
begin
  TestEqualsFreeBoth(CreateValue(2), FFails.Recover(function(E: Exception): T begin Result := CreateValue(2); end).Value);
end;

procedure TTestTry<T>.FailureShouldRaiseOnGetValue;
begin
  Assert.WillRaise(procedure begin FFails.Value end, ETestException);
end;

procedure TTestTry<T>.FailureRaiseExceptionIfShouldRaise;
begin
  Assert.WillRaise(procedure begin FFails.RaiseExceptionIf end, ETestException);
end;

procedure TTestTry<T>.FailureTryOp;
begin
  Assert.IsTrue(FFails.Op.Map<string>(function(V: T): String begin Result := 'test' end).IsFailure);
end;

procedure TTestTry<T>.IsFailure;
begin
  Assert.IsTrue(FFails.IsFailure);
  Assert.IsFalse(FOk.IsFailure);
end;

procedure TTestTry<T>.IsSuccess;
begin
  Assert.IsFalse(FFails.IsSuccess);
  Assert.IsTrue(FOk.IsSuccess);
end;

procedure TTestTry<T>.ResolveFail;
begin
  Assert.Rejects(FFails.Resolve());
end;

procedure TTestTry<T>.ResolveOk;
begin
  Assert.Resolves(FOk.Resolve());
end;

procedure TTestTry<T>.Setup;
begin
  inherited;
  FOk := TTry.Of<T>(function: T begin Result := CreateValue(1) end);
  FFails := TTry.Of<T>(function: T begin raise ETestException.Create('Test exception') end);
end;

procedure TTestTry<T>.SuccessGetValue;
begin
  TestEqualsFreeBoth(CreateValue(1), FOk.Value);
end;

procedure TTestTry<T>.SuccessRaiseExceptionIf;
begin
  Assert.WillNotRaise(procedure begin FOk.RaiseExceptionIf; end);
end;

procedure TTestTry<T>.SuccessMapReturnFailure;
begin
  Assert.IsTrue(FOk.Map(function(V: T): T begin raise ETestException.Create('') end).IsFailure);
end;

procedure TTestTry<T>.SuccessMapReturnSameValue;
begin
  TestEqualsFreeBoth(CreateValue(1), FOk.Map(function(V: T): T begin Result := V end).Value);
end;

procedure TTestTry<T>.SuccessMapReturnSuccess;
begin
  TestEqualsFreeBoth(CreateValue(5), FOk.Map(function(V: T): T begin Result := CreateValue(5) end).Value);
end;

procedure TTestTry<T>.SuccessMapTryReturnFailure;
begin
  Assert.IsTrue(FOk.Map(function(V: T): ITry<T> begin Result := TTry.Of<T>(function: T begin raise ETestException.Create('') end) end).IsFailure);
end;

procedure TTestTry<T>.SuccessMapTryReturnSuccess;
begin
  TestEqualsFreeBoth(CreateValue(5), FOk.Map(function(V: T): ITry<T> begin Result := TTry.Of<T>(function: T begin Result := CreateValue(5) end) end).Value);
end;

procedure TTestTry<T>.SuccessRecoverDoesNothing;
begin
  TestEqualsFreeBoth(CreateValue(1), FOk.Recover(function(E: Exception): T begin Result := CreateValue(2); end).Value);
end;

procedure TTestTry<T>.SuccessRecoverTryDoesNothing;
begin
  TestEqualsFreeBoth(CreateValue(1), FOk.Recover(function(E: Exception): ITry<T> begin Result := TTry.Of<T>(function: T begin Result := CreateValue(2); end) end).Value);
end;

procedure TTestTry<T>.TryOfFail;
begin
  Assert.IsTrue(TTry.&Of<T>(function: ITry<T> begin Result := FFails end).IsFailure());
end;

procedure TTestTry<T>.TryOfFailure;
begin
  Assert.IsTrue((FFails as TObject).ClassType = TFailure<T>);
end;

procedure TTestTry<T>.TryOfSuccess;
begin
  Assert.IsTrue((FOk as TObject).ClassType = TSuccess<T>);
end;

procedure TTestTry<T>.TryOfOk;
begin
  Assert.IsTrue(TTry.&Of<T>(function: ITry<T> begin Result := FOk end).IsSuccess());
end;

procedure TTestTry<T>.SuccessTryOp;
begin
  Assert.AreEqual('test', FOk.Op.Map<String>(function(V: T): String begin Result := 'test' end).Value);
end;

{ TMyObject }

constructor TMyObject.Create(AValue: Integer);
begin
  FValue := AValue;
end;

function TMyObject.Equals(AItem: TObject): Boolean;
begin
  Result := AItem is TMyObject;
  if Result then
    Result := FValue = TMyObject(AItem).FValue;
end;

{ TTestTry }

procedure TTestTryOnObject.AcceptKeepsValue;
var
  o: TMyObject;
begin
  o := FOk.Accept(procedure(v: TMyObject) begin end).Value;
  Assert.IsNotNull(o);
  o.Free;
end;

procedure TTestTryOnObject.Setup;
begin
  inherited;

  FOk := TTry.&Of<TMyObject>(function: TMyObject
    begin
      Result := TMyObject.Create(123);
    end)
end;

procedure TTestTryOnObject.SuccessTryOp;
begin
  Assert.AreEqual(123, FOk.Op
    .Map<Integer>(function(V: TMyObject): Integer
      begin
        Result := V.FValue;
      end).Value);
end;

procedure TTestTryOnObject.SuccessTryOpMapTry;
begin
  Assert.AreEqual(123, FOk.Op
    .Map<Integer>(function(V: TMyObject): ITry<Integer>
      begin
        Result := TTry.Of<Integer>(function: Integer
          begin
            Result := V.FValue;
          end);
      end).Value);
end;

procedure TTestTryOnObject.TryOpToListKeep;
var
  LList: TObjectList<TMyObject>;
begin
  LList := FOk.Op
    .Map<TObjectList<TMyObject>>(function(o: TMyObject): TObjectList<TMyObject>
      begin
        Result := TObjectList<TMyObject>.Create();
        Result.Add(o)
      end, TDisposeValue.dvKeep)
    //Make sure that recover has no impact on dvKeep
    .Recover(function(e: Exception): TObjectList<TMyObject>
      begin
        Result := TObjectList<TMyObject>.Create();
      end)
    .Value;
  try
    Assert.AreEqual(123, LList.Items[0].FValue);
  finally
    LList.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTry<Integer>);
  TDUnitX.RegisterTestFixture(TTestTry<String>);
  TDUnitX.RegisterTestFixture(TTestTry<TSimpleRecord>);
  TDUnitX.RegisterTestFixture(TTestTry<TMyObject>);
  TDUnitX.RegisterTestFixture(TTestTryOnObject);
end.
