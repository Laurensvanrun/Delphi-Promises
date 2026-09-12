unit TestPromiseAllSettled;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.SyncObjs, System.Classes,
  Next.Core.Promises, Next.Core.Promises.Exceptions, Next.Core.Test.Assert,
  Next.Core.Test.GenericTest, Next.Core.TestPromises;

type
  [TestFixture]
  TTestPromiseAllSettled<T> = class(TGenericTest<T>)
  public
    [Test]    procedure EmptyArrayResolvesEmpty;
    [Test]    procedure AllResolve;
    [Test]    procedure AllReject;
    [Test]    procedure MixedResults;
    [Test]    procedure OrderPreserved;
    [Test]    procedure SingleResolvedPromise;
    [Test]    procedure SingleRejectedPromise;
  end;

  [TestFixture]
  TTestPromiseAllSettledConcurrency = class
  public
    [Test]
    procedure StressTestManyPromises;
  end;

implementation

{ TTestPromiseAllSettled<T> }

procedure TTestPromiseAllSettled<T>.EmptyArrayResolvesEmpty;
var
  LPromise: IPromise<TArray<TPromiseSettledResult<T>>>;
  LResults: TArray<TPromiseSettledResult<T>>;
begin
  LPromise := Promise.AllSettled<T>([]);
  Assert.Resolves(LPromise);
  LResults := LPromise.Await;
  Assert.AreEqual(0, Length(LResults));
end;

procedure TTestPromiseAllSettled<T>.AllResolve;
var
  LPromise: IPromise<TArray<TPromiseSettledResult<T>>>;
  LResults: TArray<TPromiseSettledResult<T>>;
begin
  LPromise := Promise.AllSettled<T>([
    Promise.Resolve<T>(function: T begin Result := CreateValue(1) end),
    Promise.Resolve<T>(function: T begin Result := CreateValue(2) end),
    Promise.Resolve<T>(function: T begin Result := CreateValue(3) end)
  ]);

  Assert.Resolves(LPromise);
  LResults := LPromise.Await;

  Assert.AreEqual(3, Length(LResults));
  Assert.AreEqual(Ord(TPromiseStatus.psResolved), Ord(LResults[0].Status));
  TestEqualsFreeExpected(CreateValue(1), LResults[0].Value);
  Assert.IsNull(LResults[0].Error);

  Assert.AreEqual(Ord(TPromiseStatus.psResolved), Ord(LResults[1].Status));
  TestEqualsFreeExpected(CreateValue(2), LResults[1].Value);

  Assert.AreEqual(Ord(TPromiseStatus.psResolved), Ord(LResults[2].Status));
  TestEqualsFreeExpected(CreateValue(3), LResults[2].Value);
end;

procedure TTestPromiseAllSettled<T>.AllReject;
var
  LPromise: IPromise<TArray<TPromiseSettledResult<T>>>;
  LResults: TArray<TPromiseSettledResult<T>>;
begin
  LPromise := Promise.AllSettled<T>([
    Promise.Reject<T>(ETestException.Create('error1')),
    Promise.Reject<T>(ETestException.Create('error2'))
  ]);

  Assert.Resolves(LPromise);
  LResults := LPromise.Await;

  Assert.AreEqual(2, Length(LResults));
  Assert.AreEqual(Ord(TPromiseStatus.psRejected), Ord(LResults[0].Status));
  Assert.IsNotNull(LResults[0].Error);
  Assert.AreEqual('error1', LResults[0].Error.Message);

  Assert.AreEqual(Ord(TPromiseStatus.psRejected), Ord(LResults[1].Status));
  Assert.IsNotNull(LResults[1].Error);
  Assert.AreEqual('error2', LResults[1].Error.Message);
end;

procedure TTestPromiseAllSettled<T>.MixedResults;
var
  LPromise: IPromise<TArray<TPromiseSettledResult<T>>>;
  LResults: TArray<TPromiseSettledResult<T>>;
begin
  LPromise := Promise.AllSettled<T>([
    Promise.Resolve<T>(function: T begin Result := CreateValue(42) end),
    Promise.Reject<T>(ETestException.Create('failed')),
    Promise.Resolve<T>(function: T begin Result := CreateValue(99) end)
  ]);

  Assert.Resolves(LPromise);
  LResults := LPromise.Await;

  Assert.AreEqual(3, Length(LResults));

  // First: resolved
  Assert.AreEqual(Ord(TPromiseStatus.psResolved), Ord(LResults[0].Status));
  TestEqualsFreeExpected(CreateValue(42), LResults[0].Value);
  Assert.IsNull(LResults[0].Error);

  // Second: rejected
  Assert.AreEqual(Ord(TPromiseStatus.psRejected), Ord(LResults[1].Status));
  Assert.IsNotNull(LResults[1].Error);
  Assert.AreEqual('failed', LResults[1].Error.Message);

  // Third: resolved
  Assert.AreEqual(Ord(TPromiseStatus.psResolved), Ord(LResults[2].Status));
  TestEqualsFreeExpected(CreateValue(99), LResults[2].Value);
end;

procedure TTestPromiseAllSettled<T>.OrderPreserved;
var
  LSignals: array[0..2] of TEvent;
  LPromise: IPromise<TArray<TPromiseSettledResult<T>>>;
  LResults: TArray<TPromiseSettledResult<T>>;
  i: Integer;
begin
  for i := 0 to 2 do
    LSignals[i] := TEvent.Create;
  try
    LPromise := Promise.AllSettled<T>([
      Promise.Resolve<T>(function: T
        begin
          LSignals[0].WaitFor;
          Result := CreateValue(100);
        end),
      Promise.Resolve<T>(function: T
        begin
          LSignals[1].WaitFor;
          Result := CreateValue(200);
        end),
      Promise.Resolve<T>(function: T
        begin
          LSignals[2].WaitFor;
          Result := CreateValue(300);
        end)
    ]);

    // Signal in reverse order to test that results match input order
    LSignals[2].SetEvent;
    Sleep(10);
    LSignals[1].SetEvent;
    Sleep(10);
    LSignals[0].SetEvent;

    Assert.Resolves(LPromise);
    LResults := LPromise.Await;

    Assert.AreEqual(3, Length(LResults));
    TestEqualsFreeExpected(CreateValue(100), LResults[0].Value);
    TestEqualsFreeExpected(CreateValue(200), LResults[1].Value);
    TestEqualsFreeExpected(CreateValue(300), LResults[2].Value);
  finally
    for i := 0 to 2 do
      LSignals[i].Free;
  end;
end;

procedure TTestPromiseAllSettled<T>.SingleResolvedPromise;
var
  LPromise: IPromise<TArray<TPromiseSettledResult<T>>>;
  LResults: TArray<TPromiseSettledResult<T>>;
begin
  LPromise := Promise.AllSettled<T>([
    Promise.Resolve<T>(function: T begin Result := CreateValue(5) end)
  ]);

  Assert.Resolves(LPromise);
  LResults := LPromise.Await;

  Assert.AreEqual(1, Length(LResults));
  Assert.AreEqual(Ord(TPromiseStatus.psResolved), Ord(LResults[0].Status));
  TestEqualsFreeExpected(CreateValue(5), LResults[0].Value);
end;

procedure TTestPromiseAllSettled<T>.SingleRejectedPromise;
var
  LPromise: IPromise<TArray<TPromiseSettledResult<T>>>;
  LResults: TArray<TPromiseSettledResult<T>>;
begin
  LPromise := Promise.AllSettled<T>([
    Promise.Reject<T>(ETestException.Create('single error'))
  ]);

  Assert.Resolves(LPromise);
  LResults := LPromise.Await;

  Assert.AreEqual(1, Length(LResults));
  Assert.AreEqual(Ord(TPromiseStatus.psRejected), Ord(LResults[0].Status));
  Assert.IsNotNull(LResults[0].Error);
  Assert.AreEqual('single error', LResults[0].Error.Message);
end;

{ TTestPromiseAllSettledConcurrency }

function MakeResolvePromise(AValue: Integer): IPromise<Integer>;
begin
  Result := Promise.Resolve<Integer>(function: Integer begin Result := AValue end);
end;

function MakeRejectPromise(AIndex: Integer): IPromise<Integer>;
begin
  Result := Promise.Reject<Integer>(ETestException.Create('error' + IntToStr(AIndex)));
end;

procedure TTestPromiseAllSettledConcurrency.StressTestManyPromises;
var
  LPromises: TArray<IPromise<Integer>>;
  LPromise: IPromise<TArray<TPromiseSettledResult<Integer>>>;
  LResults: TArray<TPromiseSettledResult<Integer>>;
  i: Integer;
const
  COUNT = 50;
begin
  SetLength(LPromises, COUNT);
  for i := 0 to COUNT - 1 do
  begin
    if i mod 2 = 0 then
      LPromises[i] := MakeResolvePromise(i)
    else
      LPromises[i] := MakeRejectPromise(i);
  end;

  LPromise := Promise.AllSettled<Integer>(LPromises);
  Assert.Resolves(LPromise);
  LResults := LPromise.Await;

  Assert.AreEqual(COUNT, Length(LResults));
  for i := 0 to COUNT - 1 do
  begin
    if i mod 2 = 0 then
    begin
      Assert.AreEqual(Ord(TPromiseStatus.psResolved), Ord(LResults[i].Status));
      Assert.AreEqual(i, LResults[i].Value);
    end
    else
    begin
      Assert.AreEqual(Ord(TPromiseStatus.psRejected), Ord(LResults[i].Status));
      Assert.IsNotNull(LResults[i].Error);
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPromiseAllSettled<Integer>);
  TDUnitX.RegisterTestFixture(TTestPromiseAllSettled<Boolean>);
  TDUnitX.RegisterTestFixture(TTestPromiseAllSettled<String>);
  TDUnitX.RegisterTestFixture(TTestPromiseAllSettled<TSimpleRecord>);
  TDUnitX.RegisterTestFixture(TTestPromiseAllSettled<TMyObject>);
  TDUnitX.RegisterTestFixture(TTestPromiseAllSettledConcurrency);

end.
