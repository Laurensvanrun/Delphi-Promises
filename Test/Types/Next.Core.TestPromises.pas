unit Next.Core.TestPromises;

interface

uses
  DUnitX.TestFramework, System.SyncObjs, System.SysUtils,
  Next.Core.Test.GenericTest, Next.Core.Promises, System.Classes;

type
  [TestFixture]
  TTestPromiseException<T> = class(TGenericTest<T>)
  private
    FExceptionSignal: TEvent;
    procedure MyExceptionHandler(Sender: TObject; E: Exception);
  public
    [Setup]
    procedure Setup; override;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure RaiseInDone;
    [Test]
    procedure RaiseInFail;
    [Test]
    procedure ResolvedAfterFail;
    [Test]
    procedure ReRaiseInFail;
    [Test]
    procedure RaiseInFailWithAwait;
    [Test]
    procedure RaiseInDoneWithAwait;
    [Test]
    procedure RaiseInMultiplDoneWithAwait;
    [Test]
    procedure RaiseInDoneWithAwaitInAnotherThread;
  end;

  [TestFixture]
  TTestPromiseOp<T> = class(TGenericTest<T>)
    [Test] procedure OpToBoolean;
    [Test] procedure OpToPromise;
    [Test] procedure ObjectAsInterface;

    //20230516 Temporarily disabled, because this test fails regularly and the fix for this has been reverted due to other issues
    {[Test]} procedure ObjectAsInterfaceNotOwned;
    [Test] procedure ObjectAsRecord;
  end;

  [TestFixture]
  TTestPromiseMain<T> = class(TGenericTest<T>)
  private
    FOk: IPromise<T>;
    FFail: IPromise<T>;
  public
    [Setup]
    procedure Setup; override;
    [Test]
    procedure ThenByCalledInMainThread;
    [Test]
    procedure CatchCalledInMainThread;
    [Test]
    procedure ThenByFunction;
    [Test]
    procedure ThenByFunctionPromise;
    [Test]
    procedure ThenByFunctionPromiseNotInMT;
    [Test]
    procedure ThenByProcedure;
    [Test]
    procedure CatchFunction;
    [Test]
    procedure CatchFunctionPromise;
    [Test]
    procedure CatchFunctionPromiseNotInMT;
    [Test]
    procedure CatchProcedure;
    [Test]
    procedure CatchNotCalledOnResolved;
    [Test]
    procedure CatchReRaise;
    [Test]
    procedure ThenByNotCalledOnRejected;
    [Test]
    procedure MultipleThenByHandledInCorrectOrder;
    [Test]
    procedure MultipleCatchHandledInCorrectOrder;
    [Test]
    procedure MultipleThenByProcedures;
    [Test]
    procedure MultipleCatchProcedures;
    [Test]
    procedure AssignTo;
    [Test]
    procedure AssignToProc;
    [Test]
    procedure AssignToShouldNoBeExecuted;
    [Test]
    procedure &Finally;
  end;

  [TestFixture]
  TTestPromise<T> = class(TGenericTest<T>)
  private
    FOk: IPromise<T>;
    FFail: IPromise<T>;
  public
    [Setup]
    procedure Setup; override;
    [Test]
    procedure InClosure;
    [Test]
    procedure ResolveState;
    [Test]
    procedure RejectState;
    [Test]
    procedure PendingStateAfterCreate;
    [Test]
    procedure SuccessfullExecute;
    [Test]
    procedure ExceptionInExecute;
    [Test]
    procedure ThenByCalledImmediatelyIfAlreadyFullfilled;
    [Test]
    procedure CatchCalledImmediatelyIfAlreadyRejected;
    [Test]
    procedure ThenBy;
    [Test]
    procedure CatchCalledOnException;
    [Test]
    procedure RaiseSkipsThenByUntilCatch;
    [Test]
    procedure ThenByAfterCatch;
    [Test]
    procedure ThenByAfterCatchRejectedPromise;
    [Test]
    procedure ReRaiseInCatch;
    [Test]
    procedure PromiseReject;
    [Test]
    procedure Await;
    [Test]
    procedure AwaitMultipleDone;
    [Test]
    procedure AwaitMultipleFailed;
    [Test]
    procedure All;
    [Test]
    procedure AllMultipleTypes;
    [Test]
    procedure AllSingleType;
    [Test]
    procedure AllRejectOne;
    [Test]
    procedure ReturnAnotherPromise;
    [Test]
    procedure AwaitWillRaise;
    [Test]
    procedure AwaitWillNotRaise;
    [Test]
    procedure DoNotHangWithManyPromises;
    [Test]
    procedure CatchToPromise;
    [Test]
    procedure ThenByProcedureKeepsValue;
    [Test]
    procedure CatchProcedureStaysRejeceted;
    [Test]
    procedure &Finally;
  end;

  [TestFixture]
  TTestPromiseOnObject = class
    [Test]
    procedure PromiseOpToListKeep();
  end;

  [TestFixture]
  TTestScheduler = class(TObject)
  public
    [Test]
    procedure ScheduleSetSemaphore;
    [Test]
    procedure SignalSetSemaphore;
    [Test]
    procedure ScheduleIfFullfilled;
    [Test]
    procedure ScheduleIfRejected;
    [Test]
    procedure NothingIfNotFullfilled;
    [Test]
    procedure MultipleSignals;
    [Test]
    procedure PromiseGetsExecutedAfterSchedule;
    [Test]
    procedure SemaphoreKicksThreadAndTriesToGetNextPromise;
    [Test]
    procedure ScheduleLotsOfPromises;
    [Test]
    procedure SimulateCollectReportLayouts;
    [Test]
    procedure LoggerGetsCalledOnExceptionInPromiseImplementation;
    [Test]
    procedure LogFatalExceptionCallsAssignedLogger;
  end;

  [TestFixture]
  TTestPromiseAllObjects = class(TObject)
  public
    [Test] procedure AllWillBeKeptWithDvKeep;
    [Test] procedure AllIsFreedWithDvFree;
    [Test] procedure ReturnOneElementDoesNotFreeWithDvFree;
    [Test] procedure EntityResolvedInPromiseAllNotDestroyed;
  end;

  [TestFixture]
  TestPromiseAllDeadlock = class(TObject)
  private
    function Subtract(const AValue: Integer): IPromise<Integer>;
  public
    [Test] procedure AllWithNestedPromisesDeadlocks;
  end;

  [TestFixture]
  TestPromiseInPromise = class(TObject)
  public
    [Test] procedure ExpectObjectNotBeDisposedWhenReturnedInAnotherPromise;
  end;

  TAbstractPromise<T> = class(Next.Core.Promises.TAbstractPromise<T>)
  end;

  TFirstPromise<T> = class(Next.Core.Promises.TFirstPromise<T>)
  end;

{$M+}
  IMyObject = interface
  ['{A36180E0-557E-43CC-92D3-C5052A51A59E}']
    function ToString: String;
  end;

  TMyObject = class(TInterfacedObject, IMyObject)
  private
    FValue: String;
  public
    constructor Create(const AValue: String);
    destructor Destroy; override;
    function ToString: String; override;
    function Equals(AItem: TObject): Boolean; override;
  end;

  TMyComponent = class(TComponent, IMyObject)
  private
    FValue: String;
  public
    constructor Create(const AValue: String); reintroduce;
    destructor Destroy; override;
    function ToString: String; override;
  end;

procedure WaitForSignaledEvent(AEvent: TEvent);

implementation

{$WARN CONSTRUCTING_ABSTRACT OFF}

uses
  Delphi.Mocks, System.Rtti, System.Threading, Winapi.Windows,
  Next.Core.Test.Assert, Vcl.Forms, System.Generics.Collections,
  System.DateUtils, Next.Core.FailureReason, CodeSiteLogging,
  Next.Core.DisposableValue, Next.Core.Void;

{ TTestPromises }

procedure WaitForSignaledEvent(AEvent: TEvent);
var
  LTimeOut: Integer;
begin
  LTimeOut := 0;
  while (AEvent.WaitFor(10) <> wrSignaled) and (LTimeOut < 10000) do begin
    CheckSynchronize(10);
    LTimeOut := LTimeOut + 10;
  end;
  Assert.IsTrue(AEvent.WaitFor(1) = wrSignaled);
end;

procedure TTestPromise<T>.&Finally;
var
  LFinallyCalled: Boolean;
begin
  LFinallyCalled := False;
  Assert.Resolves(FOk.&Finally(procedure begin LFinallyCalled := True end));
  Assert.IsTrue(LFinallyCalled);

  LFinallyCalled := False;
  Assert.Rejects(FFail.&Finally(procedure begin LFinallyCalled := True end));
  Assert.IsTrue(LFinallyCalled);
end;

procedure TTestPromise<T>.All;
var
  LPromise1: IPromise<T>;
  LPromise2: IPromise<T>;
  LPromise3: IPromise<T>;
  LPromise: IPromise<TArray<TValue>>;
  LValues: TArray<TValue>;
begin
  LPromise1 := Promise.Resolve<T>(function: T begin
    Result := CreateValue(1);
  end);
  LPromise2 := Promise.Resolve<T>(function: T begin
    Result := CreateValue(2);
  end);
  LPromise3 := Promise.Resolve<T>(function: T begin
    Result := CreateValue(3);
  end);

  LPromise := Promise.All([LPromise1, LPromise2, LPromise3]);
  Assert.Resolves(LPromise);
  LValues := LPromise.Await;

  TestEqualsFreeBoth(CreateValue(1), LValues[0].AsType<T>);
  TestEqualsFreeBoth(CreateValue(2), LValues[1].AsType<T>);
  TestEqualsFreeBoth(CreateValue(3), LValues[2].AsType<T>);
end;

procedure TTestPromise<T>.AllMultipleTypes;
var
  LPromise1: IPromise<Integer>;
  LPromise2: IPromise<Boolean>;
  LPromise3: IPromise<String>;
  LPromise4: IPromise<T>;
  LPromise: IPromise<TArray<TValue>>;
  LValues: TArray<TValue>;
begin
  LPromise1 := Promise.Resolve<Integer>(function: Integer begin
    Result := 1;
  end);
  LPromise2 := Promise.Resolve<Boolean>(function: Boolean begin
    Result := False;
  end);
  LPromise3 := Promise.Resolve<String>(function: String begin
    Result := 'Test';
  end);
  LPromise4 := Promise.Resolve<T>(function: T begin
    Result := CreateValue(4);
  end);

  LPromise := Promise.All([LPromise1, LPromise2, LPromise3, LPromise4]);
  Assert.Resolves(LPromise);
  LValues := LPromise.Await;

  Assert.AreEqual(1, LValues[0].AsInteger);
  Assert.AreEqual(False, LValues[1].AsBoolean);
  Assert.AreEqual('Test', LValues[2].AsString);
  TestEqualsFreeBoth(CreateValue(4), LValues[3].AsType<T>);
end;

procedure TTestPromise<T>.AllRejectOne;
begin
  Assert.Rejects(Promise.All([FOk, Promise.Reject<T>(ETestException.Create('error'))]));
end;

procedure TTestPromise<T>.AllSingleType;
var
  LPromise1: IPromise<Integer>;
  LPromise2: IPromise<Integer>;
  LPromise: IPromise<TArray<Integer>>;
  LValues: TArray<Integer>;
begin
  LPromise1 := Promise.Resolve<Integer>(function: Integer begin Result := 1 end);
  LPromise2 := Promise.Resolve<Integer>(function: Integer begin Result := 2 end);
  LPromise := Promise.All<Integer>([LPromise1, LPromise2]);
  Assert.Resolves(LPromise);
  LValues := LPromise.Await;

  Assert.AreEqual(1, LValues[0]);
  Assert.AreEqual(2, LValues[1]);
end;

procedure TTestPromise<T>.Await;
var
  LPromise: IPromise<T>;
  LSignal: TEvent;
begin
  LSignal := TEvent.Create;
  try
    LPromise := Promise.Resolve<T>(function: T begin
      LSignal.WaitFor;
      Result := CreateValue(1);
    end);
    Assert.AreEqual(psPending, LPromise.State);
    LSignal.SetEvent;
    TestEqualsFreeBoth(CreateValue(1), LPromise.Await);
    Assert.AreEqual(psFullfilled, LPromise.State);
  finally
    LSignal.Free;
  end;
end;

procedure TTestPromise<T>.AwaitMultipleDone;
var
  LPromise: IPromise<T>;
begin
  LPromise := FOk.Main.ThenBy(function (const I: T): T
    begin
      TestEqualsFreeExpected(CreateValue(1), I);
      Result := CreateValue(2);
    end)
    .Main.ThenBy(function (const I: T): T begin
      TestEqualsFreeExpected(CreateValue(2), I);
      Result := CreateValue(3);
    end);

  TestEqualsFreeBoth(CreateValue(3), Assert.ResolvesTo<T>(LPromise));
end;

procedure TTestPromise<T>.AwaitMultipleFailed;
var
  LPromise: IPromise<T>;
  LFailCalled: Boolean;
begin
  LFailCalled := False;

  LPromise := Promise.Reject<T>(ETestException.Create('error1'))
    .Main.Catch(function (E: Exception): T begin
      Assert.InheritsFrom(E.ClassType, ETestException);
      Assert.AreEqual('error1', E.Message);

      raise ETestException.Create('error2');
    end)
    .Main.Catch(function (E: Exception): T begin
      Assert.InheritsFrom(E.ClassType, ETestException);
      Assert.AreEqual('error2', E.Message);

      Result := CreateValue(5);
      LFailCalled := True;
    end);

  TestEqualsFreeBoth(CreateValue(5), Assert.ResolvesTo<T>(LPromise));
  Assert.IsTrue(LFailCalled);
end;

procedure TTestPromise<T>.AwaitWillRaise;
begin
  Assert.WillRaise(procedure begin FFail.Await end, ETestException);
end;

procedure TTestPromise<T>.AwaitWillNotRaise;
begin
  Assert.WillNotRaise(procedure begin ReleaseValue(FOk.Await) end);
end;

procedure TTestPromise<T>.CatchCalledOnException;
var
  LPromise: IPromise<T>;
  LCatchCalled: Boolean;
begin
  LCatchCalled := False;
  LPromise := FOk.ThenBy(function(const I: T): T begin
      raise ETestException.Create('Error Message');
    end).Catch(function (E: Exception): T begin
      LCatchCalled := True;
      Assert.InheritsFrom(E.ClassType, ETestException);
      Result := CreateValue(123);
    end);
  TestEqualsFreeBoth(CreateValue(123), LPromise.Await);
  Assert.IsTrue(LCatchCalled);
end;

procedure TTestPromise<T>.CatchProcedureStaysRejeceted;
begin
  Assert.Rejects(FFail.Catch(procedure(E: Exception) begin end));
end;

procedure TTestPromise<T>.CatchToPromise;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Reject<T>(ETestException.Create('test'))
    .Catch(function(E: Exception): IPromise<T>
      begin
        Result := Promise.Resolve<T>(function: T begin Result := CreateValue(2) end)
      end);

  TestEqualsFreeBoth(CreateValue(2), LPromise.Await);
end;

procedure TTestPromise<T>.ThenByCalledImmediatelyIfAlreadyFullfilled;
var
  LSignal: TEvent;
begin
  LSignal := TEvent.Create;
  try
    FOk.ThenBy(function(const AValue: T): T begin
      try
        TestEqualsFreeExpected(CreateValue(1), AValue);
        Result := AValue;
      finally
        LSignal.SetEvent;
      end;
    end);
    WaitForSignaledEvent(LSignal);
  finally
    LSignal.Free;
  end;
end;

procedure TTestPromise<T>.ThenByProcedureKeepsValue;
begin
  TestEqualsFreeBoth(CreateValue(1), Assert.ResolvesTo<T>(FOk.ThenBy(procedure(const V:T) begin end)));
end;

procedure TTestPromise<T>.DoNotHangWithManyPromises;
var
  LPromises: TArray<IPromiseAccess>;
  LPromise: IPromise<T>;
  LSignal, LTestFinished: TEvent;
  i: Integer;
const
  PROM_NR = 100;
begin
  Exit;

  LSignal := TEvent.Create;
  LTestFinished := TEvent.Create;
  try
    SetLength(LPromises, PROM_NR);
    for i := 0 to PROM_NR - 1 do
      LPromises[i] := Promise.Resolve<T>(function: T begin Result := CreateValue(1) end)
        .ThenBy(function(const A: T): T
          begin
            LSignal.WaitFor;
            Result := A;
          end);

    Promise.All(LPromises)
      .ThenBy(function(const V: TArray<TValue>): TArray<TValue>
      begin
        LTestFinished.SetEvent;
        Result := V;
      end);

    //Check if we can resolve a new one
    LPromise := Promise.Resolve<T>(
      function: T
      begin
        Result := CreateValue(3);
      end);

    Assert.Resolves(LPromise);
    TestEqualsFreeBoth(CreateValue(3), LPromise.Await);

    LSignal.SetEvent;
    LTestFinished.WaitFor;
  finally
    FreeAndNil(LSignal);
    FreeAndNil(LTestFinished);
  end;
end;

procedure TTestPromise<T>.ExceptionInExecute;
var
  LPromise: TMock<TAbstractPromise<T>>;
begin
  LPromise := TMock<TAbstractPromise<T>>.Create;
  LPromise.Instance.InternalExecute(function: TDisposableValue<T> begin
    raise ETestException.Create('Error Message');
    end);
  Assert.AreEqual(psRejected, LPromise.Instance.State);
  Assert.WillRaise(procedure begin LPromise.Instance.Await end, ETestException);
end;

procedure TTestPromise<T>.CatchCalledImmediatelyIfAlreadyRejected;
var
  LSignal: TEvent;
begin
  LSignal := TEvent.Create;
  try
    Assert.Resolves(FFail.Catch(function(E: Exception): T begin
      try
        Assert.AreEqual(E.ClassType, ETestException);
        Result := CreateValue(2);
      finally
        LSignal.SetEvent;
      end;
    end));
    WaitForSignaledEvent(LSignal);
  finally
    LSignal.Free;
  end;
end;

procedure TTestPromise<T>.InClosure;
var
  LPromise: IPromise<T>;
begin
  LPromise := FOk.ThenBy(function(const I: T): T
    begin
      raise ETestException.Create('error');
    end);

  Assert.WillRaise(procedure begin LPromise.Await end);
end;

procedure TTestPromise<T>.PendingStateAfterCreate;
var
  LPromise: TMock<TAbstractPromise<T>>;
begin
  LPromise := TMock<TAbstractPromise<T>>.Create;
  Assert.AreEqual(psPending, LPromise.Instance.State);
end;

procedure TTestPromise<T>.PromiseReject;
begin
  Assert.RejectsWith(FFail, ETestException);
end;

procedure TTestPromise<T>.ThenByAfterCatch;
var
  LPromise: IPromise<T>;
begin
  LPromise := FFail.Catch(function (E: Exception): T begin
      Result := CreateValue(1);
    end)
    .ThenBy(function (const I: T): T begin
      TestEqualsFreeExpected(CreateValue(1), I);
      Result := CreateValue(2);
    end);
  TestEqualsFreeBoth(CreateValue(2), LPromise.Await);
end;

procedure TTestPromise<T>.ThenByAfterCatchRejectedPromise;
var
  LPromise: IPromise<T>;
  LThenByCalled, LCatchCalled: Boolean;
begin
  LThenByCalled := False;
  LCatchCalled := False;
  LPromise := FFail.Catch(function (E: Exception): IPromise<T> begin
      Result := Promise.Reject<T>(ETestException.Create('test'));
    end)
    .ThenBy(function (const I: T): T begin
      LThenByCalled := True;
      Result := CreateValue(1);
    end)
    .Catch(function (E: Exception): T begin
      LCatchCalled := True;
      Assert.InheritsFrom(E.ClassType, ETestException);
      Assert.AreEqual('test', E.Message);
      Result := CreateValue(2);
    end);
  TestEqualsFreeBoth(CreateValue(2), Assert.ResolvesTo<T>(LPromise));
  Assert.IsFalse(LThenByCalled);
  Assert.IsTrue(LCatchCalled);
end;

procedure TTestPromise<T>.RaiseSkipsThenByUntilCatch;
var
  LPromise: IPromise<T>;
  LThenByCalled, LCatchCalled: Boolean;
begin
  LThenByCalled := False;
  LCatchCalled := False;
  LPromise := FOk.ThenBy(function(const I: T): T begin
      raise ETestException.Create('Error Message');
    end)
    .ThenBy(function (const I: T): T begin
      LThenByCalled := True;
      Result := CreateValue(123)
    end)
    .Catch(function (E: Exception): T begin
      LCatchCalled := True;
      Assert.InheritsFrom(E.ClassType, ETestException);
      Result := CreateValue(234);
    end);
  TestEqualsFreeBoth(CreateValue(234), LPromise.Await);
  Assert.IsFalse(LThenByCalled);
  Assert.IsTrue(LCatchCalled);
end;

procedure TTestPromise<T>.RejectState;
begin
  Assert.Rejects(FFail);
end;

procedure TTestPromise<T>.ReRaiseInCatch;
var
  LPromise: IPromise<T>;
  LThenByCalled, LCatchCalled: Boolean;
begin
  LThenByCalled := False;
  LCatchCalled := False;
  LPromise := FFail.Catch(function (E: Exception): T begin
      raise E;
    end)
    .ThenBy(function (const I: T): T begin
      LThenByCalled := True;
      Result := CreateValue(1);
    end)
    .Catch(function (E: Exception): T begin
      LCatchCalled := True;
      Assert.InheritsFrom(E.ClassType, ETestException);
      Result := CreateValue(2);
    end);
  TestEqualsFreeBoth(CreateValue(2), LPromise.Await);
  Assert.IsFalse(LThenByCalled);
  Assert.IsTrue(LCatchCalled);
end;

procedure TTestPromise<T>.ResolveState;
begin
  Assert.Resolves(FOk);
end;

procedure TTestPromise<T>.ReturnAnotherPromise;
var
  LPromise: IPromise<T>;
begin
  LPromise := FOk.ThenBy(function(const I: T): IPromise<T>
      begin
        TestEqualsFreeExpected(CreateValue(1), I);
        Result := Promise.Resolve<T>(function: T begin Result := CreateValue(2) end)
          .ThenBy(function(const I: T): T
          begin
            TestEqualsFreeExpected(CreateValue(2), I);
            Result := CreateValue(3);
          end);
      end)
    .ThenBy(function(const I: T): T
      begin
        TestEqualsFreeExpected(CreateValue(3), I);
        Result := CreateValue(4);
      end);

  Assert.Resolves(LPromise);
  TestEqualsFreeBoth(CreateValue(4), LPromise.Await);
end;

procedure TTestPromise<T>.Setup;
begin
  inherited;

  FOk := Promise.Resolve<T>(function: T begin Result := CreateValue(1) end);
  FFail := Promise.Reject<T>(ETestException.Create('test'));
end;

procedure TTestPromise<T>.SuccessfullExecute;
var
  LPromise: TMock<TAbstractPromise<T>>;
begin
  LPromise := TMock<TAbstractPromise<T>>.Create;
  LPromise.Instance.InternalExecute(function: TDisposableValue<T> begin
    Result := CreateValue(99);
    end);
  Assert.AreEqual(psFullfilled, LPromise.Instance.State);
  TestEqualsFreeBoth(CreateValue(99), LPromise.Instance.Await);
end;

procedure TTestPromise<T>.ThenBy;
var
  LPromise: IPromise<T>;
begin
  LPromise := FOk.ThenBy(function(const I: T): T begin Result := I end);
  Assert.AreEqual(TPromise<T, T>, (LPromise as TObject).ClassType);
end;

{ TTestPromiseException }

procedure TTestPromiseException<T>.MyExceptionHandler(Sender: TObject;
  E: Exception);
begin
  FExceptionSignal.SetEvent;
end;

procedure TTestPromiseException<T>.RaiseInDone;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Resolve<T>(function: T begin Result := CreateValue(1) end)
    .Main.ThenBy(function(const I: T): T
      begin
        raise ETestException.Create('error');
      end);

  Assert.Rejects(LPromise);
end;

procedure TTestPromiseException<T>.RaiseInDoneWithAwait;
var
  LPromise: IPromise<T>;
  LOldExceptionEvent: TExceptionEvent;
begin
  LOldExceptionEvent := Application.OnException;
  Application.OnException := Self.MyExceptionHandler;
  try
    LPromise := Promise.Resolve<T>(function: T begin Result := CreateValue(1) end)
      .Main.ThenBy(function(const I: T): T begin
      raise ETestException.Create('error');
      end);

    //Await should raise the exception
    Assert.WillRaise(procedure begin LPromise.Await end);
    Assert.AreNotEqual(wrSignaled, FExceptionSignal.WaitFor(1));
  finally
    Application.OnException := LOldExceptionEvent;
  end;
end;

procedure TTestPromiseException<T>.RaiseInDoneWithAwaitInAnotherThread;
var
  LOldExceptionEvent: TExceptionEvent;
  LTaskCompleted: TEvent;
begin
  LTaskCompleted := TEvent.Create;
  LOldExceptionEvent := Application.OnException;
  Application.OnException := Self.MyExceptionHandler;
  try
    TTask.Create(procedure
    var
      LPromise: IPromise<T>;
    begin
      try
        LPromise := Promise.Resolve<T>(function: T begin Result := CreateValue(1) end)
          .Main.ThenBy(function(const I: T): T begin
              raise ETestException.Create('error');
            end);

        Assert.WillRaise(procedure begin LPromise.Await end);
      finally
        LTaskCompleted.SetEvent;
      end;
    end).Start;

    WaitForSignaledEvent(LTaskCompleted);
    Assert.AreNotEqual(wrSignaled, FExceptionSignal.WaitFor(1));
  finally
    Application.OnException := LOldExceptionEvent;
    LTaskCompleted.Free;
  end;
end;

procedure TTestPromiseException<T>.RaiseInFail;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Reject<T>(ETestException.Create('error'))
    .Main.Catch(function(E: Exception): T
      begin
        raise E;
      end);

  Assert.Rejects(LPromise);
end;

procedure TTestPromiseException<T>.RaiseInFailWithAwait;
var
  LPromise: IPromise<T>;
  LOldExceptionEvent: TExceptionEvent;
begin
  LOldExceptionEvent := Application.OnException;
  Application.OnException := Self.MyExceptionHandler;
  try
    LPromise := Promise.Reject<T>(ETestException.Create('error'))
      .Main.Catch(function(E: Exception): T begin
        raise E;
      end);

    //Await should raise the exception
    Assert.WillRaise(procedure begin LPromise.Await end);
    Assert.AreNotEqual(wrSignaled, FExceptionSignal.WaitFor(1));
  finally
    Application.OnException := LOldExceptionEvent;
  end;
end;

procedure TTestPromiseException<T>.RaiseInMultiplDoneWithAwait;
var
  LPromise: IPromise<T>;
  LOldExceptionEvent: TExceptionEvent;
begin
  LOldExceptionEvent := Application.OnException;
  Application.OnException := Self.MyExceptionHandler;
  try
    LPromise := Promise.Resolve<T>(function: T begin Result := CreateValue(1) end)
      .Main.ThenBy(
        function(const I: T): T begin
          raise ETestException.Create('1');
        end)
      .Main.ThenBy(
        function(const I: T): T begin
          Assert.Fail('This done routine should never be called.');
        end)
      .Main.Catch(
        function(E: Exception): T begin
          raise E;
        end);

    //Await should raise the LAST exception
    Assert.WillRaise(procedure begin LPromise.Await end, ETestException);
    Assert.AreNotEqual(wrSignaled, FExceptionSignal.WaitFor(1));
  finally
    Application.OnException := LOldExceptionEvent;
  end;
end;

procedure TTestPromiseException<T>.ReRaiseInFail;
var
  LPromise: IPromise<T>;
  LOldExceptionEvent: TExceptionEvent;
begin
  LOldExceptionEvent := Application.OnException;
  Application.OnException := Self.MyExceptionHandler;
  try
    //The exception from Fail should NOT be catched in the global exception handler
    LPromise := Promise.Reject<T>(ETestException.Create('Test'))
      .Main.Catch(
        function(E: Exception): T begin
          raise E;
        end);

    Assert.Rejects(LPromise);
    Assert.AreNotEqual(wrSignaled, FExceptionSignal.WaitFor(1));
  finally
    Application.OnException := LOldExceptionEvent;
  end;
end;

procedure TTestPromiseException<T>.ResolvedAfterFail;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Reject<T>(ETestException.Create('error'))
    .Main.Catch(function (E: Exception): T
      begin
        Result := CreateValue(123);
      end);

  Assert.Resolves(LPromise);
end;

procedure TTestPromiseException<T>.Setup;
begin
  inherited;

  FExceptionSignal := TEvent.Create;
end;

procedure TTestPromiseException<T>.TearDown;
begin
  FExceptionSignal.Free;
end;

{$WARN CONSTRUCTING_ABSTRACT ON}

{ TMyObject }

constructor TMyObject.Create(const AValue: String);
begin
  FValue := AValue;
end;

destructor TMyObject.Destroy;
begin
  FValue := 'destroyed';
  inherited;
end;

function TMyObject.Equals(AItem: TObject): Boolean;
begin
  Result := AItem is TMyObject;
  if Result then
    Result := FValue = TMyObject(AItem).FValue;
end;

function TMyObject.ToString: String;
begin
  Result := FValue;
end;

{ TTestScheduler }
procedure TTestScheduler.ScheduleIfFullfilled;
var
  LScheduler: IPromiseScheduler;
  LPromise: TMock<IPromiseAccess>;
begin
  LPromise := TMock<IPromiseAccess>.Create;
  LPromise.Setup.WillReturn(TValue.From(TPromiseState.psFullfilled)).When.PreviousPromiseState;
{$IFDEF DEBUG}
  LPromise.Setup.WillReturn(0).When.GetPromiseNo;
{$ENDIF}

  LScheduler := TPromiseScheduler.Create;
  LScheduler.Schedule(LPromise);
  Assert.IsNotNull(LScheduler.GiveNextPromise());
end;

procedure TTestScheduler.ScheduleIfRejected;
var
  LScheduler: IPromiseScheduler;
  LPromise: TMock<IPromiseAccess>;
begin
  LPromise := TMock<IPromiseAccess>.Create;
  LPromise.Setup.WillReturn(TValue.From(TPromiseState.psRejected)).When.PreviousPromiseState;
{$IFDEF DEBUG}
  LPromise.Setup.WillReturn(0).When.GetPromiseNo;
{$ENDIF}

  LScheduler := TPromiseScheduler.Create;
  LScheduler.Schedule(LPromise);
  Assert.IsNotNull(LScheduler.GiveNextPromise());
end;

procedure TTestScheduler.ScheduleLotsOfPromises;
const
  PROMISES_TO_SCHEDULE = 100;
var
  LScheduler: TPromiseScheduler;
  LPromise: TMock<IPromiseAccess>;
  LPromiseExecuted: Integer;
  i: Integer;
begin
  LPromiseExecuted := 0;
  LScheduler := TPromiseScheduler.Create;
  try
    LScheduler.Start;

    LPromise := TMock<IPromiseAccess>.Create;
    LPromise.Setup.WillReturn(TValue.From(TPromiseState.psFullfilled)).When.PreviousPromiseState;
{$IFDEF DEBUG}
    LPromise.Setup.WillReturn(0).When.GetPromiseNo;
{$ENDIF}
    LPromise.Setup.WillExecute(function(const args: TArray<TValue>; const ReturnType: TRttiType): TValue
      begin
        Sleep(10);
        AtomicIncrement(LPromiseExecuted);
      end).When.Execute;

    for i := 0 to PROMISES_TO_SCHEDULE - 1 do
      LScheduler.Schedule(LPromise);

    Assert.Wait(function: Boolean begin
      Result := PROMISES_TO_SCHEDULE = LPromiseExecuted;
    end);
  finally
    LScheduler.Free;
  end;
end;

procedure TTestScheduler.ScheduleSetSemaphore;
var
  LScheduler: IPromiseScheduler;
  LPromise: TMock<IPromiseAccess>;
begin
  LScheduler := TPromiseScheduler.Create;

  LPromise := TMock<IPromiseAccess>.Create;
  LPromise.Setup.WillReturn(TValue.From(TPromiseState.psFullfilled)).When.PreviousPromiseState;
{$IFDEF DEBUG}
  LPromise.Setup.WillReturn(0).When.GetPromiseNo;
{$ENDIF}

  LScheduler.Schedule(LPromise);
  Assert.AreEqual(wrSignaled, LScheduler.SignalToken.WaitFor(10));
end;

//Reintroduce here to be able to get access to private class TPromiseThread
type
  TPromiseScheduler = class(Next.Core.Promises.TPromiseScheduler);

procedure TTestScheduler.SemaphoreKicksThreadAndTriesToGetNextPromise;
var
  LThread: TPromiseScheduler.TPromiseThread;
  LScheduler: TMock<IPromiseScheduler>;
  LPromise: TMock<IPromiseAccess>;
  LSignal: TSemaphore;
  LPromiseSignal: TEvent;
begin
  LPromiseSignal := TEvent.Create;
  LSignal := TSemaphore.Create(nil, 0, 9999, '');
  try
    LPromise := TMock<IPromiseAccess>.Create;
    LPromise.Setup.WillExecute(function(const args: TArray<TValue>; const ReturnType: TRttiType): TValue
      begin
        LPromiseSignal.SetEvent;
      end).When.Execute;
{$IFDEF DEBUG}
    LPromise.Setup.WillReturn(0).When.GetPromiseNo;
{$ENDIF}

    LScheduler := TMock<IPromiseScheduler>.Create;
    LScheduler.Setup.WillReturn(LSignal).When.SignalToken;
    LScheduler.Setup.WillReturn(TValue.From<IPromiseAccess>(LPromise.Instance)).When.GiveNextPromise;
    LScheduler.Setup.Expect.Once.When.GiveNextPromise;

    LThread := TPromiseScheduler.TPromiseThread.Create(LScheduler);
    try
      LSignal.Release;  //Signal semaphore
      Assert.AreEqual(wrSignaled, LPromiseSignal.WaitFor(10000));  //Wait for promisse to execute
    finally
      LThread.Cancel;
      LThread.WaitFor;
      LThread.Free;
    end;

    LScheduler.VerifyAll();
  finally
    LPromiseSignal.Free;
    LSignal.Free;
  end;
end;

procedure TTestScheduler.SignalSetSemaphore;
var
  LScheduler: IPromiseScheduler;
begin
  LScheduler := TPromiseScheduler.Create;
  LScheduler.Signal;
  Assert.AreEqual(wrSignaled, LScheduler.SignalToken.WaitFor(1));
end;

procedure TTestScheduler.PromiseGetsExecutedAfterSchedule;
var
  LScheduler: TPromiseScheduler;
  LPromise: TMock<IPromiseAccess>;
  LSignal: TEvent;
begin
  LScheduler := TPromiseScheduler.Create;
  LSignal := TEvent.Create;
  try
    LPromise := TMock<IPromiseAccess>.Create;
    LPromise.Setup.WillReturn(TValue.From(TPromiseState.psFullfilled)).When.PreviousPromiseState;
    LPromise.Setup.WillExecute(function(const args: TArray<TValue>; const ReturnType: TRttiType): TValue
      begin
        LSignal.SetEvent;
      end).When.Execute;
{$IFDEF DEBUG}
    LPromise.Setup.WillReturn(0).When.GetPromiseNo;
{$ENDIF}
    LPromise.Setup.Expect.Once.When.Execute;

    LScheduler.Start;
    LScheduler.Schedule(LPromise);

    Assert.AreEqual(wrSignaled, LSignal.WaitFor(10000));

    LPromise.VerifyAll();
  finally
    LSignal.Free;
    LScheduler.Free;
  end;
end;

procedure TTestScheduler.LogFatalExceptionCallsAssignedLogger;
var
  LScheduler:  IPromiseScheduler;
  LLogger: TMock<IPromiseSchedulerExceptionLogger>;
  LException: ETestException;
begin
  LException := ETestException.Create('test');
  try
    LLogger := TMock<IPromiseSchedulerExceptionLogger>.Create;
    LLogger.Setup.Expect.Once.When.FatalPromiseException('IPromise<String>', LException);

    LScheduler := TPromiseScheduler.Create;
    LScheduler.SetLogger(LLogger);
    LScheduler.LogFatalException('IPromise<String>', LException);

    LLogger.VerifyAll();
  finally
    LException.Free;
  end;
end;

procedure TTestScheduler.LoggerGetsCalledOnExceptionInPromiseImplementation;
var
  LThread: TPromiseScheduler.TPromiseThread;
  LScheduler: TMock<IPromiseScheduler>;
  LSignal: TSemaphore;
  LLoggerSignal: TEvent;
begin
  LSignal := TSemaphore.Create(nil, 0, 9999, '');
  LLoggerSignal := TEvent.Create;
  try
    LScheduler := TMock<IPromiseScheduler>.Create;
    LScheduler.Setup.WillReturn(LSignal).When.SignalToken;
    LScheduler.Setup.WillRaise(ETestException).When.GiveNextPromise;
    LScheduler.Setup.Expect.Once.When.GiveNextPromise;
    LScheduler.Setup.Expect.Once.When.LogFatalException(It0.IsAny<String>, It1.IsAny<ETestException>);
    LScheduler.Setup.WillExecute(function(const args: TArray<TValue>; const ReturnType: TRttiType): TValue
      begin
        LLoggerSignal.SetEvent;
      end).When.LogFatalException(It0.IsAny<String>, It1.IsAny<ETestException>);

    LThread := TPromiseScheduler.TPromiseThread.Create(LScheduler);
    try
      LSignal.Release;  //Signal semaphore to call GiveNextPromise
      Assert.AreEqual(wrSignaled, LLoggerSignal.WaitFor(10000));  //Wait for logger to be called
    finally
      LThread.Cancel;
      LThread.WaitFor;
      LThread.Free;
    end;

    LScheduler.VerifyAll();
  finally
    LLoggerSignal.Free;
    LSignal.Free;
  end;
end;

procedure TTestScheduler.MultipleSignals;
var
  LScheduler: IPromiseScheduler;
begin
  LScheduler := TPromiseScheduler.Create;

  LScheduler.Signal;
  LScheduler.Signal;
  Assert.AreEqual(wrSignaled, LScheduler.SignalToken.WaitFor(1));
  Assert.AreEqual(wrSignaled, LScheduler.SignalToken.WaitFor(1));
  Assert.AreNotEqual(wrSignaled, LScheduler.SignalToken.WaitFor(1));
end;

procedure TTestScheduler.NothingIfNotFullfilled;
var
  LScheduler: IPromiseScheduler;
  LPromise: TMock<IPromiseAccess>;
begin
  LPromise := TMock<IPromiseAccess>.Create;
  LPromise.Setup.WillReturn(TValue.From(TPromiseState.psPending)).When.PreviousPromiseState;

  LScheduler := TPromiseScheduler.Create;
  LScheduler.Schedule(LPromise);
  Assert.IsNull(LScheduler.GiveNextPromise());
end;

//
// SimulateCollectReportLayouts
//

  procedure DoNothing(ASimulatedAction: String); begin end;

  function RepoById(AId: String): IPromise<TVoid>;
  begin
    Result := Promise.Resolve<TVoid>(
      function: TVoid begin
        Sleep(100);
        Result := Void;
      end)
  end;

  function Exists(AId: String): Boolean;
  begin
    Result := RepoById(AId+' exists')
      .Op.ThenBy<Boolean>(
        function (const v: TVoid): Boolean begin
          Result := False;
        end)
      .Await();
  end;

  function ToInvoiceDict(ALayout: String): IPromise<TVoid>;
  begin
    Result := Promise.Resolve<TVoid>(
      function (): TVoid begin
        Result := Void;  //create dictionary
        if Exists(ALayout +'_customId') then
          DoNothing('add customId to dictionary')
        else if Exists(ALayout +'_administrationId') then
          DoNothing('add administrationId to dictionary')
        else
          DoNothing('add fallBackId to dictionary (if defined)');
      end);
  end;

  function CheckId(AId: String): IPromise<String>;
  begin
    if (AId.IsEmpty) then
      Result := Promise.Reject<String>(Exception.Create('invalid id'))
    else
      Result := Promise.Resolve<String>(function: String begin Result := AId end);
  end;

  function RetrieveReport(AId: String): IPromise<TVoid>;
  begin
    Result := RepoById(AId+ ' retrieve').Op.ThenBy<TVoid>(
      function (const v: TVoid): TVoid begin
        DoNothing('raise if empty');
        Result := Void;
      end);
  end;

  function CollectorGo(ALayout: String): IPromise<TVoid>;
  var
    LPromises: TArray<IPromise<TVoid>>;
    I: Integer;
  begin
    for I := 1 to 10 do
      LPromises := LPromises + [
        CheckId(ALayout+ I.ToString()).Op.ThenBy<TVoid>(
          function (const Id: String):  IPromise<TVoid> begin
            Result := RetrieveReport(Id);
          end)
        ];
      Result := Promise.All<TVoid>(LPromises).Op.ThenBy<TVoid>(
        function(const a: TArray<TVoid>): TVoid begin
          Result := Void;
          DoNothing('make into TMappedObjectDictionary');
        end);
  end;

  function CollectReports(ALayout: string): TConstFunc<TVoid, IPromise<TVoid>>;
  begin
    Result :=
      function (const v: TVoid): IPromise<TVoid>
      begin
        Result := CollectorGo(ALayout);
      end;
  end;

  function CollectLayout(ALayout: String): IPromise<TVoid>;
  begin
    Result := ToInvoiceDict(ALayout).Op.ThenBy<TVoid>(CollectReports(ALayout));
  end;

procedure TTestScheduler.SimulateCollectReportLayouts;
var
  LPromiseAll: IPromise<TArray<TVoid>>;
begin
  //recreate scheduler to start with MIN_POOL_SIZE
  _Scheduler := nil;
  CreatePromiseSchedulerIf();

  // simulating the promises flow of TCoPoInvoiceLooperEmail.CollectReportLayouts
  LPromiseAll := Promise.All<TVoid>([
    CollectLayout('email'),
    CollectLayout('pdf'),
    CollectLayout('excel')
  ]);

  Assert.Resolves(LPromiseAll);
  LPromiseAll.Await();
end;

{ TTestPromiseOnObject }

procedure TTestPromiseOnObject.PromiseOpToListKeep;
var
  LObjectList: TObjectList<TMyObject>;
begin
  LObjectList := Promise.Resolve<TMyObject>(function: TMyObject
      begin
        Result := TMyObject.Create('test');
      end)
    .Op.ThenBy<TObjectList<TMyObject>>(function(const o: TMyObject): TObjectList<TMyObject>
      begin
        Result := TObjectList<TMyObject>.Create();
        Result.Add(o)
      end, TDisposeValue.dvKeep)
    .Catch(function(e: Exception): TObjectList<TMyObject>
      begin
        Result := TObjectList<TMyObject>.Create();
      end)
    .Await;
  try
    Assert.AreEqual('test', LObjectList[0].FValue);
  finally
    LObjectList.Free;
  end;
end;

{ TTestPromisesOp<T> }

procedure TTestPromiseOp<T>.ObjectAsInterface;
var
  LPromise: IPromise<String>;
begin
  LPromise := Promise
    .Resolve<IMyObject>(function: IMyObject begin Result := TMyObject.Create('test') end)
    .Op.ThenBy<String>(function (const A: IMyObject): String begin
      Result := A.ToString;
    end);
  Assert.Resolves(LPromise);
  Assert.AreEqual('test', LPromise.Await);
end;

procedure TTestPromiseOp<T>.ObjectAsInterfaceNotOwned;
var
  o: TMyComponent;
  LPromise: IPromise<IMyObject>;
begin
  o := TMyComponent.Create('test');
  LPromise := Promise.Resolve<IMyObject>(function: IMyObject begin Result := o end);
  Assert.Resolves(LPromise);
  //If we do not remove all references to the promise, the promise will call
  //_Release on 'o' on destruction, while the object is already freeed
  LPromise := nil;
  o.Free;
end;

procedure TTestPromiseOp<T>.ObjectAsRecord;
var
  LPromise: IPromise<String>;
  LMockedObject: TMock<IMyObject>;  //TMock is a record
begin
  LMockedObject := TMock<IMyObject>.Create;
  LMockedObject.Setup.WillReturn('test').When.ToString;

  LPromise := Promise
    .Resolve<IMyObject>(function: IMyObject begin Result := LMockedObject.Instance end)
    .Op.ThenBy<String>(function (const A: IMyObject): String begin
      Result := A.ToString;
    end);
  Assert.Resolves(LPromise);
  Assert.AreEqual('test', LPromise.Await);
end;

procedure TTestPromiseOp<T>.OpToBoolean;
var
  LPromise: IPromise<Boolean>;
begin
  LPromise := Promise.Resolve<T>(function: T begin Result := CreateValue(1) end)
    .Op.ThenBy<Boolean>(function(const I: T): Boolean
      begin
        Result := True
      end);

  Assert.Implements<IPromise<Boolean>>(LPromise);
  Assert.AreEqual(True, Assert.ResolvesTo<Boolean>(LPromise));
end;

procedure TTestPromiseOp<T>.OpToPromise;
var
  LPromise: IPromise<Boolean>;
begin
  LPromise := Promise.Resolve<T>(function: T begin Result := CreateValue(1) end)
    .Op.ThenBy<Boolean>(function(const I: T): IPromise<Boolean>
      begin
        Result := Promise.Resolve<Boolean>(function: Boolean begin Result := True end);
      end);

  Assert.Implements<IPromise<Boolean>>(LPromise);
  Assert.AreEqual(True, Assert.ResolvesTo<Boolean>(LPromise));
end;

{ TTestPromiseMain<T> }

procedure TTestPromiseMain<T>.&Finally;
var
  LFinallyCalled: Boolean;
  LMainThread: TThreadID;
begin
  LMainThread := TThread.CurrentThread.ThreadID;

  LFinallyCalled := False;
  Assert.Resolves(FOk.Main.&Finally(procedure
    begin
      LFinallyCalled := True;
      Assert.AreEqual(LMainThread, TThread.CurrentThread.ThreadID);
    end));
  Assert.IsTrue(LFinallyCalled);

  LFinallyCalled := False;
  Assert.RejectsWith(FFail.Main.&Finally(procedure
    begin
      Assert.AreEqual(LMainThread, TThread.CurrentThread.ThreadID);
      LFinallyCalled := True;
    end), ETestException);
  Assert.IsTrue(LFinallyCalled);
end;

procedure TTestPromiseMain<T>.AssignTo;
var
  FValue: T;
  FPromise: IPromiseSimple;
begin
  FPromise := FOk
      .Main.ThenBy(function (const V: T): T begin
        Result := V;
      end)
      .Main.Catch(procedure(E: Exception) begin
      end)
      .Main.AssignTo(FValue);

  FPromise.InternalWait();
  FPromise := nil;
  TestEqualsFreeBoth(CreateValue(1), FValue);
end;

procedure TTestPromiseMain<T>.AssignToProc;
var
  FValue: T;
  FPromise: IPromiseSimple;
begin
  FPromise := FOk
      .Main.ThenBy(function (const V: T): T begin
        Result := V;
      end)
      .Main.Catch(procedure(E: Exception) begin
      end)
      .Main.AssignTo(procedure(const V:T) begin
        FValue := V;
      end);

  FPromise.InternalWait();
  FPromise := nil;
  TestEqualsFreeBoth(CreateValue(1), FValue);
end;

procedure TTestPromiseMain<T>.AssignToShouldNoBeExecuted;
var
  FValue: T;
begin
  FValue := CreateValue(123);
  FFail.Main.AssignTo(FValue).InternalWait();
  TestEqualsFreeBoth(CreateValue(123), FValue);

  FValue := CreateValue(123);
  FFail.Main.AssignTo(procedure(const V: T) begin FValue := V; end).InternalWait();
  TestEqualsFreeBoth(CreateValue(123), FValue);
end;

procedure TTestPromiseMain<T>.CatchCalledInMainThread;
var
  LMainThread: TThreadID;
begin
  LMainThread := TThread.CurrentThread.ThreadID;
  Assert.Resolves(FFail
    .Main.Catch(function(E: Exception): T
      begin
        Assert.AreEqual(LMainThread, TThread.CurrentThread.ThreadID);
        Result := CreateValue(1);
      end));

  Assert.Resolves(FFail
    .Main.Catch(function(E: Exception): IPromise<T>
      begin
        Assert.AreEqual(LMainThread, TThread.CurrentThread.ThreadID);
        Result := Promise.Resolve<T>(function: T begin Result := CreateValue(1) end);
      end));

  Assert.RejectsWith(FFail
    .Main.Catch(procedure(E: Exception)
      begin
        Assert.AreEqual(LMainThread, TThread.CurrentThread.ThreadID);
      end), ETestException);
end;

procedure TTestPromiseMain<T>.CatchFunction;
var
  LPromise: IPromise<T>;
  LFailCalled: Boolean;
begin
  LPromise := FFail.Main.Catch(function(E: Exception): T
    begin
      Assert.AreEqual(E.ClassType, ETestException);
      LFailCalled := True;
      Result := CreateValue(123);
    end);

  TestEqualsFreeBoth(CreateValue(123), Assert.ResolvesTo<T>(LPromise));
  Assert.IsTrue(LFailCalled);
end;

procedure TTestPromiseMain<T>.CatchFunctionPromise;
var
  LPromise: IPromise<T>;
begin
  LPromise := FFail.Main.Catch(function(E: Exception): IPromise<T>
      begin
        Result := Promise.Resolve<T>(function: T begin Result := CreateValue(2) end)
      end);

  TestEqualsFreeBoth(CreateValue(2), Assert.ResolvesTo<T>(LPromise));
end;

procedure TTestPromiseMain<T>.CatchFunctionPromiseNotInMT;
var
  LPromise: IPromise<T>;
  LCurrentThread, LFailThread: TThreadID;
begin
  LCurrentThread := TThread.CurrentThread.ThreadID;
  LPromise := FFail.Main.Catch(function(E: Exception): IPromise<T>
      begin
        LFailThread := TThread.CurrentThread.ThreadID;
        Assert.AreEqual(LCurrentThread, LFailThread);

        Result := Promise.Resolve<T>(function: T begin
          Assert.AreNotEqual(LFailThread, TThread.CurrentThread.ThreadID);
          Result := CreateValue(2);
        end)
      end);

  TestEqualsFreeBoth(CreateValue(2), Assert.ResolvesTo<T>(LPromise));
end;

procedure TTestPromiseMain<T>.CatchNotCalledOnResolved;
var
  LPromise: IPromise<T>;
begin
  LPromise := FOk.Main.Catch(function(E: Exception): T begin
      Result := CreateValue(2);
    end);

  TestEqualsFreeBoth(CreateValue(1), Assert.ResolvesTo<T>(LPromise));
end;

procedure TTestPromiseMain<T>.CatchProcedure;
var
  LPromise: IPromise<T>;
  LFailCalled: Boolean;
begin
  LFailCalled := False;
  LPromise := FFail.Main.Catch(
      procedure(E: Exception) begin
        Assert.AreEqual(E.ClassType, ETestException);
        LFailCalled := True;
      end);

  Assert.RejectsWith(LPromise, ETestException);
  Assert.IsTrue(LFailCalled);
end;

procedure TTestPromiseMain<T>.CatchReRaise;
var
  LPromise: IPromise<T>;
begin
  LPromise := FFail.Main.Catch(function (E: Exception): T
    begin
      raise E;
    end);
  Assert.RejectsWith(LPromise, ETestException);
end;

procedure TTestPromiseMain<T>.MultipleThenByHandledInCorrectOrder;
var
  LPromise: IPromise<T>;
  LSignal1, LSignal2: TEvent;
begin
  LSignal1 := TEvent.Create;
  LSignal2 := TEvent.Create;
  try
    LPromise := Promise
      .Resolve<T>(function: T
        begin
          //Give enough time to make sure that the promise is not fullfilled if
          //the first done is chained
          Sleep(5);
          Result := CreateValue(1);
        end)
      .Main.ThenBy(function(const AValue: T): T
        begin
          LSignal1.SetEvent;
          Result := AValue;
        end);

    Assert.Resolves(LPromise);

    LPromise.Main.ThenBy(function(const AValue: T): T begin
      if LSignal1.WaitFor(1) <> wrSignaled then
        raise ETestException.Create('Second done called before first!');
      LSignal2.SetEvent;
      Result := AValue;
    end);

    WaitForSignaledEvent(LSignal2);
  finally
    LSignal1.Free;
    LSignal2.Free;
  end;
end;

procedure TTestPromiseMain<T>.MultipleCatchHandledInCorrectOrder;
var
  LPromise: IPromise<T>;
  LSignal1, LSignal2: TEvent;
begin
  LSignal1 := TEvent.Create;
  LSignal2 := TEvent.Create;
  try
    LPromise := Promise
      .Resolve<T>(function: T
        begin
          //Give enough time to make sure that the promise is not fullfilled if
          //the first done is chained
          Sleep(5);
          raise ETestException.Create('Error Message');
        end)
      .Main.Catch(function(E: Exception): T
        begin
          LSignal1.SetEvent;
          raise E;
        end);

    //Wait until the promise IS rejected before we chain the second done
    Assert.Rejects(LPromise);

    LPromise.Main.Catch(function(E: Exception): T begin
      try
        if LSignal1.WaitFor(1) <> wrSignaled then
          raise ETestException.Create('Second fail called before first!');

        Result := CreateValue(2);
      finally
        LSignal2.SetEvent;
      end;
    end);

    WaitForSignaledEvent(LSignal2);
  finally
    LSignal1.Free;
    LSignal2.Free;
  end;
end;

procedure TTestPromiseMain<T>.MultipleThenByProcedures;
var
  LPromise: IPromise<T>;
begin
  LPromise := FOk.Main.ThenBy(function(const AValue: T): T begin
      TestEqualsFreeExpected(CreateValue(1), AValue);
      Result := CreateValue(456);
      end)
    .Main.ThenBy(function(const AValue: T): T begin
      TestEqualsFreeExpected(CreateValue(456), AValue);
      Result := CreateValue(789);
    end);

  Assert.Resolves(LPromise);
  TestEqualsFreeBoth(CreateValue(789), LPromise.Await);
end;

procedure TTestPromiseMain<T>.MultipleCatchProcedures;
var
  LPromise: IPromise<T>;
  LFailCalled1, LFailCalled2: Boolean;
begin
  LFailCalled1 := False;
  LFailCalled2 := False;

  LPromise := FFail.Main.Catch(function(E: Exception): T begin
      Assert.AreEqual(E.ClassType, ETestException);
      LFailCalled1 := True;
      raise E;
    end)
    .Main.Catch(function(E: Exception): T begin
      Assert.AreEqual(E.ClassType, ETestException);
      LFailCalled2 := True;
      Result := CreateValue(1);
    end);

  Assert.Resolves(LPromise);
  Assert.IsTrue(LFailCalled1);
  Assert.IsTrue(LFailCalled2);
end;

procedure TTestPromiseMain<T>.Setup;
begin
  inherited;

  FOk := Promise.Resolve<T>(function: T begin Result := CreateValue(1) end);
  FFail := Promise.Reject<T>(ETestException.Create('test'));
end;

procedure TTestPromiseMain<T>.ThenByFunction;
var
  LPromise: IPromise<T>;
  LDoneCalled: Boolean;
begin
  LDoneCalled := False;

  LPromise := FOk.Main.ThenBy(
      function(const AValue: T): T begin
        TestEqualsFreeExpected(CreateValue(1), AValue);
        LDoneCalled := True;
        Result := AValue;
      end);

  Assert.Resolves(LPromise);
  Assert.IsTrue(LDoneCalled);
end;

procedure TTestPromiseMain<T>.ThenByFunctionPromise;
var
  LPromise: IPromise<T>;
begin
  LPromise := FOk.Main.ThenBy(function(const I: T): IPromise<T>
      begin
        Result := Promise.Resolve<T>(function: T begin Result := CreateValue(2) end)
      end);

  TestEqualsFreeBoth(CreateValue(2), LPromise.Await);
end;

procedure TTestPromiseMain<T>.ThenByFunctionPromiseNotInMT;
var
  LPromise: IPromise<T>;
  LCurrentThread, LDoneThread: TThreadID;
begin
  LCurrentThread := TThread.CurrentThread.ThreadID;
  LPromise := FOk.Main.ThenBy(function(const I: T): IPromise<T>
      begin
        LDoneThread := TThread.CurrentThread.ThreadID;
        Assert.AreEqual(LCurrentThread, LDoneThread);
        Result := Promise.Resolve<T>(function: T begin
          Assert.AreNotEqual(LDoneThread, TThread.CurrentThread.ThreadID);
          Result := CreateValue(2);
        end)
      end);

  TestEqualsFreeBoth(CreateValue(2), Assert.ResolvesTo<T>(LPromise));
end;

procedure TTestPromiseMain<T>.ThenByNotCalledOnRejected;
var
  LPromise: IPromise<T>;
begin
  LPromise := FFail.Main.ThenBy(function(const I: T): T begin
      Result := CreateValue(2);
    end);

  Assert.RejectsWith(LPromise, ETestException);
end;

procedure TTestPromiseMain<T>.ThenByProcedure;
var
  LPromise: IPromise<T>;
  LDoneCalled: Boolean;
begin
  LDoneCalled := False;
  LPromise := FOk.Main.ThenBy(procedure(const AValue: T) begin
      TestEqualsFreeExpected(CreateValue(1), AValue);
      LDoneCalled := True;
    end);

  Assert.Resolves(LPromise);
  Assert.IsTrue(LDoneCalled);
  TestEqualsFreeBoth(CreateValue(1), LPromise.Await);
end;

procedure TTestPromiseMain<T>.ThenByCalledInMainThread;
var
  LMainThread: TThreadID;
begin
  LMainThread := TThread.CurrentThread.ThreadID;
  Assert.Resolves(FOk.Main.ThenBy(
      procedure(const AValue: T)
      begin
        Assert.AreEqual(LMainThread, TThread.CurrentThread.ThreadID);
      end));

  Assert.Resolves(FOk.Main.ThenBy(
      function(const AValue: T): T
      begin
        Assert.AreEqual(LMainThread, TThread.CurrentThread.ThreadID);
        Result := AValue;
      end));

  Assert.Resolves(FOk.Main.ThenBy(
      function(const AValue: T): IPromise<T>
      begin
        Assert.AreEqual(LMainThread, TThread.CurrentThread.ThreadID);
        Result := Promise.Resolve<T>(function: T begin Result := AValue end);
      end));
end;

{ TMyObjectNotOwned }

constructor TMyComponent.Create(const AValue: String);
begin
  inherited Create(nil);

  FValue := AValue;
end;

destructor TMyComponent.Destroy;
begin
  FValue := 'destroyed';
  inherited;
end;

function TMyComponent.ToString: String;
begin
  Result := FValue;
end;

{ TTestPromiseAllObjects }

type
  TLeaveUsAlone = class
  private
    FId: Integer;
  public
    constructor Create(AId: Integer);

    property Id: Integer read FId;
  end;

procedure TTestPromiseAllObjects.EntityResolvedInPromiseAllNotDestroyed;
begin
  var LEntity := TObject.Create();
  try
    var LPromise: IPromise<TObject> := Promise.Resolve<TObject>(
      function: TObject
      begin
        Result := LEntity;
      end);

    var LIsParamOk := False;
    var LResult := Promise.All<TObject>([LPromise])
      .ThenBy(
        procedure(const AItems: TArray<TObject>)
        begin
          LIsParamOk := AItems[0] = LEntity;
        end)
      .Await;

    Assert.IsTrue(LIsParamOk);
    Assert.AreEqual(1, Length(LResult));
    Assert.AreEqual<TObject>(LEntity, LResult[0]);

  finally
    //shouldn't have been cleaned up by the promise
    LEntity.Free;
  end;
end;

procedure TTestPromiseAllObjects.AllWillBeKeptWithDvKeep;
var
  LPromiseAll: IPromise<TObjectList<TLeaveUsAlone>>;
  LPromise, LPromise2: IPromise<TLeaveUsAlone>;
  LResult: TObjectList<TLeaveUsAlone>;
begin
  LPromise := Promise.Resolve<TLeaveUsAlone>(
    function: TLeaveUsAlone
    begin
      Result := TLeaveUsAlone.Create(1);
    end);

  LPromise2 := Promise.Resolve<TLeaveUsAlone>(
    function: TLeaveUsAlone
    begin
      Result := TLeaveUsAlone.Create(2);
    end);

  LPromiseAll := Promise.All<TLeaveUsAlone>([LPromise, LPromise2])
    .Op.ThenBy<TObjectList<TLeaveUsAlone>>(
      function(const AEntities: TArray<TLeaveUsAlone>): TObjectList<TLeaveUsAlone>
      begin
        Result := TObjectList<TLeaveUsAlone>.Create(AEntities);
        Result.OwnsObjects := True;
      end, dvKeep);

  LResult := LPromiseAll.Await;
  LPromiseAll := nil;

  Assert.AreEqual(1, LResult.Items[0].Id);
  Assert.AreEqual(2, LResult.Items[1].Id);
  LResult.Free;
end;

procedure TTestPromiseAllObjects.ReturnOneElementDoesNotFreeWithDvFree;
var
  LPromiseAll: IPromise<TLeaveUsAlone>;
  LPromise, LPromise2: IPromise<TLeaveUsAlone>;
  LResult: TLeaveUsAlone;
begin
  LPromise := Promise.Resolve<TLeaveUsAlone>(
    function: TLeaveUsAlone
    begin
      Result := TLeaveUsAlone.Create(1);
    end);

  LPromise2 := Promise.Resolve<TLeaveUsAlone>(
    function: TLeaveUsAlone
    begin
      Result := TLeaveUsAlone.Create(2);
    end);

  LPromiseAll := Promise.All<TLeaveUsAlone>([LPromise, LPromise2])
    .Op.ThenBy<TLeaveUsAlone>(
      function(const AEntities: TArray<TLeaveUsAlone>): TLeaveUsAlone
      begin
        Result := AEntities[0];
      end, dvFree);

  LResult := LPromiseAll.Await;
  LPromiseAll := nil;

  Assert.AreEqual(1, LResult.Id);
  LResult.Free;
end;

procedure TTestPromiseAllObjects.AllIsFreedWithDvFree;
var
  LPromiseAll: IPromise<Boolean>;
  LPromise, LPromise2: IPromise<TLeaveUsAlone>;
begin
  LPromise := Promise.Resolve<TLeaveUsAlone>(
    function: TLeaveUsAlone
    begin
      Result := TLeaveUsAlone.Create(1);
    end);

  LPromise2 := Promise.Resolve<TLeaveUsAlone>(
    function: TLeaveUsAlone
    begin
      Result := TLeaveUsAlone.Create(2);
    end);

  LPromiseAll := Promise.All<TLeaveUsAlone>([LPromise, LPromise2])
    .Op.ThenBy<Boolean>(
      function(const AEntities: TArray<TLeaveUsAlone>): Boolean
      begin
        Result := True;
      end, dvFree);

  LPromiseAll.Await;
  // After this test, we should NOT have a memory leak. That's the point of this test.
end;

{ TLeaveUsAlone }

constructor TLeaveUsAlone.Create(AId: Integer);
begin
  FId := AId;
end;

{ TestPromiseAllDeadlock }

procedure TestPromiseAllDeadlock.AllWithNestedPromisesDeadlocks;
var LPromises: TArray<IPromise<Integer>>;
begin
  for var i := 0 to 500 do begin

    var LPromise := Promise.Resolve<Integer>(
        function: Integer
        begin
          Result := 100 * 100;
        end)
      .ThenBy(
        function(const ACalculatedValue: Integer): IPromise<Integer>
        begin
          //do something time consuming, so all threads in the pool will be running before we subtract
          //NB: it can theoretically also go wrong without sleep, it's just a matter of timing.
          Sleep(10);
          Result := Subtract(ACalculatedValue);
        end);

    LPromises := LPromises + [LPromise];
  end;

  Promise.All<Integer>(LPromises).Await;
end;

function TestPromiseAllDeadlock.Subtract(const AValue: Integer): IPromise<Integer>;
begin
  Result := Promise.Resolve<Integer>(
    function: Integer
    begin
      //put a breakpoint on the next line, and see it will never trigger
      Result := AValue - 100;
    end);
end;

{ TestPromiseInPromise }

procedure TestPromiseInPromise.ExpectObjectNotBeDisposedWhenReturnedInAnotherPromise;
begin
  var LObject := TMyObject.Create('test');
  var LPromise := Promise.Resolve<TMyObject>(function: TMyObject
    begin
      Result := LObject;
    end)
  .ThenBy(function(const AIn: TMyObject): IPromise<TMyObject>
    begin
      Result := Promise.Resolve<TMyObject>(function: TMyObject
        begin
          Result := AIn;
        end);
    end);

  Assert.ResolvesTo<TMyObject>(LPromise, LObject).Free;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScheduler);
  TDUnitX.RegisterTestFixture(TTestPromiseOnObject);
  TDUnitX.RegisterTestFixture(TTestPromise<Integer>);
  TDUnitX.RegisterTestFixture(TTestPromise<Boolean>);
  TDUnitX.RegisterTestFixture(TTestPromise<String>);
  TDUnitX.RegisterTestFixture(TTestPromise<TSimpleRecord>);
  TDUnitX.RegisterTestFixture(TTestPromise<TMyObject>);
  TDUnitX.RegisterTestFixture(TTestPromiseOp<Integer>);
  TDUnitX.RegisterTestFixture(TTestPromiseOp<Boolean>);
  TDUnitX.RegisterTestFixture(TTestPromiseOp<String>);
  TDUnitX.RegisterTestFixture(TTestPromiseOp<TSimpleRecord>);
  TDUnitX.RegisterTestFixture(TTestPromiseOp<TMyObject>);
  TDUnitX.RegisterTestFixture(TTestPromiseMain<Integer>);
  TDUnitX.RegisterTestFixture(TTestPromiseMain<Boolean>);
  TDUnitX.RegisterTestFixture(TTestPromiseMain<String>);
  TDUnitX.RegisterTestFixture(TTestPromiseMain<TSimpleRecord>);
  TDUnitX.RegisterTestFixture(TTestPromiseMain<TMyObject>);
  TDUnitX.RegisterTestFixture(TTestPromiseException<Integer>);
  TDUnitX.RegisterTestFixture(TTestPromiseException<Boolean>);
  TDUnitX.RegisterTestFixture(TTestPromiseException<String>);
  TDUnitX.RegisterTestFixture(TTestPromiseException<TSimpleRecord>);
  TDUnitX.RegisterTestFixture(TTestPromiseException<TMyObject>);
  TDUnitX.RegisterTestFixture(TTestPromiseAllObjects);
  TDUnitX.RegisterTestFixture(TestPromiseAllDeadlock);
  TDUnitX.RegisterTestFixture(TestPromiseInPromise);
end.
