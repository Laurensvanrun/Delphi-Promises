unit TestPromiseFinally;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.SyncObjs, System.Classes,
  Next.Core.Promises, Next.Core.Test.Assert,
  Next.Core.Test.GenericTest, Next.Core.TestPromises;

type
  [TestFixture]
  TTestPromiseFinally<T> = class(TGenericTest<T>)
  public
    [Test]    procedure FinallyRunsAfterResolve;
    [Test]    procedure FinallyRunsAfterReject;
    [Test]    procedure FinallyPreservesResolvedValue;
    [Test]    procedure FinallyPreservesRejection;
    [Test]    procedure FinallyRaisingReplacesResolvedResult;
    [Test]    procedure FinallyRaisingReplacesRejection;
    [Test]    procedure FinallyFollowedByThenBy;
    [Test]    procedure MainFinallyRunsAfterResolve;
  end;

implementation

{ TTestPromiseFinally<T> }

procedure TTestPromiseFinally<T>.FinallyRunsAfterResolve;
var
  LFinallyCalled: Boolean;
  LPromise: IPromise<T>;
begin
  LFinallyCalled := False;
  LPromise := Promise.Resolve<T>(function: T
    begin
      Result := CreateValue(42);
    end)
  .&Finally(procedure
    begin
      LFinallyCalled := True;
    end);

  Assert.Resolves(LPromise);
  Assert.IsTrue(LFinallyCalled);
end;

procedure TTestPromiseFinally<T>.FinallyRunsAfterReject;
var
  LFinallyCalled: Boolean;
  LPromise: IPromise<T>;
begin
  LFinallyCalled := False;
  LPromise := Promise.Reject<T>(ETestException.Create('error'))
    .&Finally(procedure
      begin
        LFinallyCalled := True;
      end);

  Assert.Rejects(LPromise);
  Assert.IsTrue(LFinallyCalled);
end;

procedure TTestPromiseFinally<T>.FinallyPreservesResolvedValue;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Resolve<T>(function: T
    begin
      Result := CreateValue(42);
    end)
  .&Finally(procedure
    begin
      // Do nothing
    end);

  Assert.Resolves(LPromise);
  TestEqualsFreeExpected(CreateValue(42), LPromise.Await);
end;

procedure TTestPromiseFinally<T>.FinallyPreservesRejection;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Reject<T>(ETestException.Create('original error'))
    .&Finally(procedure
      begin
        // Do nothing
      end);

  Assert.RejectsWith(LPromise, ETestException);
end;

procedure TTestPromiseFinally<T>.FinallyRaisingReplacesResolvedResult;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Resolve<T>(function: T
    begin
      Result := CreateValue(42);
    end)
  .&Finally(procedure
    begin
      raise ETestException.Create('finally error');
    end);

  Assert.RejectsWith(LPromise, ETestException);
end;

procedure TTestPromiseFinally<T>.FinallyRaisingReplacesRejection;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Reject<T>(EInvalidOp.Create('original'))
    .&Finally(procedure
      begin
        raise ETestException.Create('finally replaces');
      end);

  Assert.RejectsWith(LPromise, ETestException);
end;

procedure TTestPromiseFinally<T>.FinallyFollowedByThenBy;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Resolve<T>(function: T
    begin
      Result := CreateValue(42);
    end)
  .&Finally(procedure
    begin
      // Nothing
    end)
  .ThenBy(function(const V: T): T
    begin
      Result := V;
    end);

  Assert.Resolves(LPromise);
  TestEqualsFreeExpected(CreateValue(42), LPromise.Await);
end;

procedure TTestPromiseFinally<T>.MainFinallyRunsAfterResolve;
var
  LFinallyCalled: Boolean;
  LMainThread: TThreadID;
  LPromise: IPromise<T>;
begin
  LMainThread := TThread.CurrentThread.ThreadID;
  LFinallyCalled := False;

  LPromise := Promise.Resolve<T>(function: T
    begin
      Result := CreateValue(42);
    end)
  .Main.&Finally(procedure
    begin
      LFinallyCalled := True;
      Assert.AreEqual(LMainThread, TThread.CurrentThread.ThreadID);
    end);

  Assert.Resolves(LPromise);
  Assert.IsTrue(LFinallyCalled);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPromiseFinally<Integer>);
  TDUnitX.RegisterTestFixture(TTestPromiseFinally<Boolean>);
  TDUnitX.RegisterTestFixture(TTestPromiseFinally<String>);
  TDUnitX.RegisterTestFixture(TTestPromiseFinally<TSimpleRecord>);
  TDUnitX.RegisterTestFixture(TTestPromiseFinally<TMyObject>);

end.
