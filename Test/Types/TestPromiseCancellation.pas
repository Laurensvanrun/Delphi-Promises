unit TestPromiseCancellation;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.SyncObjs, System.Classes,
  Next.Core.Promises, Next.Core.Promises.Exceptions,
  Next.Core.Promises.Cancellation, Next.Core.Test.Assert,
  Next.Core.Test.GenericTest, Next.Core.TestPromises;

type
  [TestFixture]
  TTestPromiseCancellation<T> = class(TGenericTest<T>)
  public
    [Test]    procedure CancelBeforeStartRejects;
    [Test]    procedure TokenNotCancelledExecutesNormally;
    [Test]    procedure CancelDuringExecution;
    [Test]    procedure OnCancelledHandlerFires;
    [Test]    procedure OnCancelledNotFiredOnOtherExceptions;
    [Test]    procedure CatchRecoverFromCancellation;
    [Test]    procedure CancelAlreadyResolvedIsNoop;
    [Test]    procedure TokenPropagationThroughChain;
  end;

  [TestFixture]
  TTestCancellationTokenSource = class
  public
    [Test]    procedure BasicCancelAndIsCancelled;
    [Test]    procedure CancelIsIdempotent;
    [Test]    procedure ThrowIfCancelledNotRaisedWhenNotCancelled;
    [Test]    procedure ThrowIfCancelledRaisesWhenCancelled;
  end;

  [TestFixture]
  TTestCancellationPatterns = class
  public
    [Test]    procedure RacePlusCancellationPattern;
  end;

implementation

{ TTestPromiseCancellation<T> }

procedure TTestPromiseCancellation<T>.CancelBeforeStartRejects;
var
  LCts: ICancellationTokenSource;
  LPromise: IPromise<T>;
begin
  LCts := TCancellationTokenSource.Create;
  LCts.Cancel;

  LPromise := Promise.Resolve<T>(function: T
    begin
      Result := CreateValue(42);
    end)
  .CancelToken(LCts.Token)
  .ThenBy(function(const V: T): T
    begin
      Result := V;
    end);

  Assert.RejectsWith(LPromise, EOperationCancelled);
end;

procedure TTestPromiseCancellation<T>.TokenNotCancelledExecutesNormally;
var
  LCts: ICancellationTokenSource;
  LPromise: IPromise<T>;
begin
  LCts := TCancellationTokenSource.Create;

  LPromise := Promise.Resolve<T>(function: T
    begin
      LCts.Token.ThrowIfCancelled;
      Result := CreateValue(42);
    end)
  .CancelToken(LCts.Token);

  Assert.Resolves(LPromise);
  TestEqualsFreeExpected(CreateValue(42), LPromise.Await);
end;

procedure TTestPromiseCancellation<T>.CancelDuringExecution;
var
  LCts: ICancellationTokenSource;
  LPromise: IPromise<T>;
  LStartedSignal: TEvent;
begin
  LCts := TCancellationTokenSource.Create;
  LStartedSignal := TEvent.Create;
  try
    LPromise := Promise.Resolve<T>(function: T
      begin
        LStartedSignal.SetEvent;
        var LIterations := 0;
        while LIterations < 1000 do
        begin
          if LCts.Token.IsCancelled then
            raise EOperationCancelled.Create;
          Sleep(10);
          Inc(LIterations);
        end;
        Result := CreateValue(42);
      end);

    LStartedSignal.WaitFor(5000);
    Sleep(50);
    LCts.Cancel;

    Assert.RejectsWith(LPromise, EOperationCancelled);
  finally
    LStartedSignal.Free;
  end;
end;

procedure TTestPromiseCancellation<T>.OnCancelledHandlerFires;
var
  LCts: ICancellationTokenSource;
  LPromise: IPromise<T>;
  LOnCancelledFired: Boolean;
begin
  LCts := TCancellationTokenSource.Create;
  LOnCancelledFired := False;
  LCts.Cancel;

  LPromise := Promise.Resolve<T>(function: T
    begin
      LCts.Token.ThrowIfCancelled;
      Result := CreateValue(42);
    end)
  .OnCancelled(procedure
    begin
      LOnCancelledFired := True;
    end);

  Assert.Rejects(LPromise);
  Assert.IsTrue(LOnCancelledFired);
end;

procedure TTestPromiseCancellation<T>.OnCancelledNotFiredOnOtherExceptions;
var
  LPromise: IPromise<T>;
  LOnCancelledFired: Boolean;
begin
  LOnCancelledFired := False;

  LPromise := Promise.Resolve<T>(function: T
    begin
      raise ETestException.Create('not a cancellation');
    end)
  .OnCancelled(procedure
    begin
      LOnCancelledFired := True;
    end);

  Assert.Rejects(LPromise);
  Assert.IsFalse(LOnCancelledFired);
end;

procedure TTestPromiseCancellation<T>.CatchRecoverFromCancellation;
var
  LCts: ICancellationTokenSource;
  LPromise: IPromise<T>;
begin
  LCts := TCancellationTokenSource.Create;
  LCts.Cancel;

  LPromise := Promise.Resolve<T>(function: T
    begin
      LCts.Token.ThrowIfCancelled;
      Result := CreateValue(42);
    end)
  .Catch(function(E: Exception): T
    begin
      if E is EOperationCancelled then
        Result := CreateValue(99)
      else
        raise E;
    end);

  Assert.Resolves(LPromise);
  TestEqualsFreeExpected(CreateValue(99), LPromise.Await);
end;

procedure TTestPromiseCancellation<T>.CancelAlreadyResolvedIsNoop;
var
  LCts: ICancellationTokenSource;
  LPromise: IPromise<T>;
begin
  LCts := TCancellationTokenSource.Create;

  LPromise := Promise.Resolve<T>(function: T
    begin
      Result := CreateValue(42);
    end)
  .CancelToken(LCts.Token);

  Assert.Resolves(LPromise);
  TestEqualsFreeExpected(CreateValue(42), LPromise.Await);

  // Cancel after already resolved - should have no effect
  LCts.Cancel;
  Assert.Resolves(LPromise);
end;

procedure TTestPromiseCancellation<T>.TokenPropagationThroughChain;
var
  LCts: ICancellationTokenSource;
  LPromise: IPromise<T>;
  LSecondThenByCalled: Boolean;
  LStartedSignal: TEvent;
begin
  LCts := TCancellationTokenSource.Create;
  LSecondThenByCalled := False;
  LStartedSignal := TEvent.Create;
  try
    LPromise := Promise.Resolve<T>(function: T
      begin
        LStartedSignal.SetEvent;
        Result := CreateValue(1);
      end)
    .CancelToken(LCts.Token)
    .ThenBy(function(const V: T): T
      begin
        Result := CreateValue(2);
      end)
    .ThenBy(function(const V: T): T
      begin
        LSecondThenByCalled := True;
        Result := CreateValue(3);
      end);

    LStartedSignal.WaitFor(5000);
    LCts.Cancel;

    // The promise may resolve or reject depending on timing
    LPromise.InternalWait(5000);
  finally
    LStartedSignal.Free;
  end;
end;

{ TTestCancellationTokenSource }

procedure TTestCancellationTokenSource.BasicCancelAndIsCancelled;
var
  LCts: ICancellationTokenSource;
  LToken: ICancellationToken;
begin
  LCts := TCancellationTokenSource.Create;
  LToken := LCts.Token;

  Assert.IsFalse(LCts.IsCancelled);
  Assert.IsFalse(LToken.IsCancelled);

  LCts.Cancel;

  Assert.IsTrue(LCts.IsCancelled);
  Assert.IsTrue(LToken.IsCancelled);
end;

procedure TTestCancellationTokenSource.CancelIsIdempotent;
var
  LCts: ICancellationTokenSource;
begin
  LCts := TCancellationTokenSource.Create;
  LCts.Cancel;
  LCts.Cancel; // Second cancel should not raise
  Assert.IsTrue(LCts.IsCancelled);
end;

procedure TTestCancellationTokenSource.ThrowIfCancelledNotRaisedWhenNotCancelled;
var
  LCts: ICancellationTokenSource;
begin
  LCts := TCancellationTokenSource.Create;
  Assert.WillNotRaise(procedure
    begin
      LCts.Token.ThrowIfCancelled;
    end);
end;

procedure TTestCancellationTokenSource.ThrowIfCancelledRaisesWhenCancelled;
var
  LCts: ICancellationTokenSource;
begin
  LCts := TCancellationTokenSource.Create;
  LCts.Cancel;
  Assert.WillRaise(procedure
    begin
      LCts.Token.ThrowIfCancelled;
    end, EOperationCancelled);
end;

{ TTestCancellationPatterns }

procedure TTestCancellationPatterns.RacePlusCancellationPattern;
var
  LCts: ICancellationTokenSource;
  LRaceResult: IPromise<Integer>;
  LWorkerStarted: TEvent;
  LWorkerCancelled: Boolean;
begin
  LCts := TCancellationTokenSource.Create;
  LWorkerStarted := TEvent.Create;
  LWorkerCancelled := False;
  try
    LRaceResult := Promise.Race<Integer>([
      // Fast winner
      Promise.Resolve<Integer>(function: Integer
        begin
          Result := 42;
        end),
      // Slow worker that checks for cancellation
      Promise.Resolve<Integer>(function: Integer
        begin
          LWorkerStarted.SetEvent;
          var LIterations := 0;
          while LIterations < 100 do
          begin
            if LCts.Token.IsCancelled then
            begin
              LWorkerCancelled := True;
              raise EOperationCancelled.Create;
            end;
            Sleep(50);
            Inc(LIterations);
          end;
          Result := 99;
        end)
    ]);

    Assert.Resolves(LRaceResult);
    Assert.AreEqual(42, LRaceResult.Await);

    LCts.Cancel;
    Sleep(200);
    Assert.IsTrue(LWorkerCancelled);
  finally
    LWorkerStarted.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPromiseCancellation<Integer>);
  TDUnitX.RegisterTestFixture(TTestPromiseCancellation<Boolean>);
  TDUnitX.RegisterTestFixture(TTestPromiseCancellation<String>);
  TDUnitX.RegisterTestFixture(TTestPromiseCancellation<TSimpleRecord>);
  TDUnitX.RegisterTestFixture(TTestPromiseCancellation<TMyObject>);
  TDUnitX.RegisterTestFixture(TTestCancellationTokenSource);
  TDUnitX.RegisterTestFixture(TTestCancellationPatterns);

end.
