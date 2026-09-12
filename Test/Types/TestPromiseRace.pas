unit TestPromiseRace;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.SyncObjs, System.Classes,
  Next.Core.Promises, Next.Core.Promises.Exceptions, Next.Core.Test.Assert,
  Next.Core.Test.GenericTest, Next.Core.TestPromises;

type
  [TestFixture]
  TTestPromiseRace<T> = class(TGenericTest<T>)
  public
    [Test]    procedure EmptyArrayRejects;
    [Test]    procedure SinglePromiseResolves;
    [Test]    procedure SinglePromiseRejects;
    [Test]    procedure FirstResolvesWins;
    [Test]    procedure FirstRejectsRaceRejects;
    [Test]    procedure FastResolveSlowRejectIgnored;
    [Test]
    procedure RaceInChainThenBy;
    [Test]    procedure PreResolvedPromiseInRace;
    [Test]    procedure PreRejectedPromiseInRace;
  end;

  [TestFixture]
  TTestPromiseRaceConcurrency = class
  public
    [Test]
    procedure StressTestManyPromises;
    [Test]    procedure RaceAsTimeoutPattern;
  end;

implementation

{ TTestPromiseRace<T> }

procedure TTestPromiseRace<T>.EmptyArrayRejects;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Race<T>([]);
  Assert.RejectsWith(LPromise, EArgumentException);
end;

procedure TTestPromiseRace<T>.SinglePromiseResolves;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Race<T>([
    Promise.Resolve<T>(function: T
      begin
        Result := CreateValue(7);
      end)
  ]);

  Assert.Resolves(LPromise);
  TestEqualsFreeExpected(CreateValue(7), LPromise.Await);
end;

procedure TTestPromiseRace<T>.SinglePromiseRejects;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Race<T>([
    Promise.Reject<T>(ETestException.Create('single error'))
  ]);

  Assert.RejectsWith(LPromise, ETestException);
end;

procedure TTestPromiseRace<T>.FirstResolvesWins;
var
  LFastSignal: TEvent;
  LSlowSignal: TEvent;
  LPromise: IPromise<T>;
begin
  LFastSignal := TEvent.Create;
  LSlowSignal := TEvent.Create;
  try
    LPromise := Promise.Race<T>([
      Promise.Resolve<T>(function: T
        begin
          LFastSignal.WaitFor;
          Result := CreateValue(42);
        end),
      Promise.Resolve<T>(function: T
        begin
          LSlowSignal.WaitFor;
          Result := CreateValue(99);
        end)
    ]);

    LFastSignal.SetEvent;
    Assert.Resolves(LPromise);
    TestEqualsFreeExpected(CreateValue(42), LPromise.Await);

    LSlowSignal.SetEvent;
  finally
    LFastSignal.Free;
    LSlowSignal.Free;
  end;
end;

procedure TTestPromiseRace<T>.FirstRejectsRaceRejects;
var
  LPromise: IPromise<T>;
  LSlowSignal: TEvent;
begin
  LSlowSignal := TEvent.Create;
  try
    LPromise := Promise.Race<T>([
      Promise.Reject<T>(ETestException.Create('fast error')),
      Promise.Resolve<T>(function: T
        begin
          LSlowSignal.WaitFor;
          Result := CreateValue(99);
        end)
    ]);

    Assert.Rejects(LPromise);
    LSlowSignal.SetEvent;
  finally
    LSlowSignal.Free;
  end;
end;

procedure TTestPromiseRace<T>.FastResolveSlowRejectIgnored;
var
  LPromise: IPromise<T>;
  LSlowSignal: TEvent;
begin
  LSlowSignal := TEvent.Create;
  try
    LPromise := Promise.Race<T>([
      Promise.Resolve<T>(function: T
        begin
          Result := CreateValue(42);
        end),
      Promise.Resolve<T>(function: T
        begin
          LSlowSignal.WaitFor;
          raise ETestException.Create('slow error');
        end)
    ]);

    Assert.Resolves(LPromise);
    TestEqualsFreeExpected(CreateValue(42), LPromise.Await);
    LSlowSignal.SetEvent;
  finally
    LSlowSignal.Free;
  end;
end;

procedure TTestPromiseRace<T>.RaceInChainThenBy;
var
  LPromise: IPromise<String>;
begin
  LPromise := Promise.Race<T>([
    Promise.Resolve<T>(function: T
      begin
        Result := CreateValue(42);
      end)
  ])
  .Op.ThenBy<String>(function(const V: T): String
    begin
      Result := 'chained';
    end);

  Assert.Resolves(LPromise);
  Assert.AreEqual('chained', LPromise.Await);
end;

procedure TTestPromiseRace<T>.PreResolvedPromiseInRace;
var
  LPromise: IPromise<T>;
  LSlowSignal: TEvent;
begin
  LSlowSignal := TEvent.Create;
  try
    LPromise := Promise.Race<T>([
      Promise.Resolve<T>(function: T
        begin
          Result := CreateValue(1);
        end),
      Promise.Resolve<T>(function: T
        begin
          LSlowSignal.WaitFor;
          Result := CreateValue(99);
        end)
    ]);

    Assert.Resolves(LPromise);
    TestEqualsFreeExpected(CreateValue(1), LPromise.Await);
    LSlowSignal.SetEvent;
  finally
    LSlowSignal.Free;
  end;
end;

procedure TTestPromiseRace<T>.PreRejectedPromiseInRace;
var
  LPromise: IPromise<T>;
  LSlowSignal: TEvent;
begin
  LSlowSignal := TEvent.Create;
  try
    LPromise := Promise.Race<T>([
      Promise.Reject<T>(ETestException.Create('pre-rejected')),
      Promise.Resolve<T>(function: T
        begin
          LSlowSignal.WaitFor;
          Result := CreateValue(99);
        end)
    ]);

    Assert.RejectsWith(LPromise, ETestException);
    LSlowSignal.SetEvent;
  finally
    LSlowSignal.Free;
  end;
end;

{ TTestPromiseRaceConcurrency }

function MakeSignaledPromise(ASignal: TEvent; AValue: Integer): IPromise<Integer>;
begin
  Result := Promise.Resolve<Integer>(function: Integer
    begin
      ASignal.WaitFor;
      Result := AValue;
    end);
end;

procedure TTestPromiseRaceConcurrency.StressTestManyPromises;
var
  LPromises: TArray<IPromise<Integer>>;
  LSignals: TArray<TEvent>;
  LPromise: IPromise<Integer>;
  i: Integer;
const
  COUNT = 20;
begin
  SetLength(LPromises, COUNT);
  SetLength(LSignals, COUNT);

  for i := 0 to COUNT - 1 do
  begin
    LSignals[i] := TEvent.Create;
    LPromises[i] := MakeSignaledPromise(LSignals[i], i);
  end;

  LPromise := Promise.Race<Integer>(LPromises);

  // Signal the 5th promise first
  LSignals[5].SetEvent;

  Assert.Resolves(LPromise);
  Assert.AreEqual(5, LPromise.Await);

  // Clean up - signal all remaining
  for i := 0 to COUNT - 1 do
  begin
    LSignals[i].SetEvent;
    LSignals[i].Free;
  end;
end;

procedure TTestPromiseRaceConcurrency.RaceAsTimeoutPattern;
var
  LPromise: IPromise<Integer>;
begin
  LPromise := Promise.Race<Integer>([
    Promise.Resolve<Integer>(function: Integer
      begin
        Sleep(5000); // Slow work
        Result := 42;
      end),
    Promise.Resolve<Integer>(function: Integer
      begin
        Sleep(50); // Short timeout
        raise ETimeoutException.Create('Operation timed out');
      end)
  ]);

  Assert.RejectsWith(LPromise, ETimeoutException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPromiseRace<Integer>);
  TDUnitX.RegisterTestFixture(TTestPromiseRace<Boolean>);
  TDUnitX.RegisterTestFixture(TTestPromiseRace<String>);
  TDUnitX.RegisterTestFixture(TTestPromiseRace<TSimpleRecord>);
  TDUnitX.RegisterTestFixture(TTestPromiseRace<TMyObject>);
  TDUnitX.RegisterTestFixture(TTestPromiseRaceConcurrency);

end.
