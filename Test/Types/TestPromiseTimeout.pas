unit TestPromiseTimeout;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.SyncObjs, System.Classes,
  Next.Core.Promises, Next.Core.Promises.Exceptions, Next.Core.Test.Assert,
  Next.Core.Test.GenericTest, Next.Core.TestPromises;

type
  [TestFixture]
  TTestPromiseTimeout<T> = class(TGenericTest<T>)
  public
    [Test]    procedure ResolvesBeforeTimeout;
    [Test]    procedure ExceedsTimeoutRejects;
    [Test]    procedure TimeoutCustomMessage;
    [Test]
    procedure TimeoutInChainThenBy;
    [Test]    procedure CatchRecoveryFromTimeout;
    [Test]
    procedure GenerousTimeoutFastPromise;
  end;

implementation

{ TTestPromiseTimeout<T> }

procedure TTestPromiseTimeout<T>.ResolvesBeforeTimeout;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Resolve<T>(function: T
    begin
      Result := CreateValue(42);
    end)
  .Timeout(5000);

  Assert.Resolves(LPromise);
  TestEqualsFreeExpected(CreateValue(42), LPromise.Await);
end;

procedure TTestPromiseTimeout<T>.ExceedsTimeoutRejects;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Resolve<T>(function: T
    begin
      Sleep(5000);
      Result := CreateValue(42);
    end)
  .Timeout(100);

  Assert.RejectsWith(LPromise, ETimeoutException);
end;

procedure TTestPromiseTimeout<T>.TimeoutCustomMessage;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Resolve<T>(function: T
    begin
      Sleep(5000);
      Result := CreateValue(42);
    end)
  .Timeout(100, 'Custom timeout message');

  Assert.RejectsWith(LPromise, ETimeoutException);

  LPromise.InternalWait;
  Assert.AreEqual('Custom timeout message', LPromise.GetFailure.Reason.Message);
end;

procedure TTestPromiseTimeout<T>.TimeoutInChainThenBy;
var
  LPromise: IPromise<String>;
begin
  LPromise := Promise.Resolve<T>(function: T
    begin
      Result := CreateValue(42);
    end)
  .Timeout(5000)
  .Op.ThenBy<String>(function(const V: T): String
    begin
      Result := 'chained';
    end);

  Assert.Resolves(LPromise);
  Assert.AreEqual('chained', LPromise.Await);
end;

procedure TTestPromiseTimeout<T>.CatchRecoveryFromTimeout;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Resolve<T>(function: T
    begin
      Sleep(5000);
      Result := CreateValue(42);
    end)
  .Timeout(100)
  .Catch(function(E: Exception): T
    begin
      if E is ETimeoutException then
        Result := CreateValue(99)
      else
        raise E;
    end);

  Assert.Resolves(LPromise);
  TestEqualsFreeExpected(CreateValue(99), LPromise.Await);
end;

procedure TTestPromiseTimeout<T>.GenerousTimeoutFastPromise;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Resolve<T>(function: T
    begin
      Result := CreateValue(1);
    end)
  .Timeout(30000);

  Assert.Resolves(LPromise);
  TestEqualsFreeExpected(CreateValue(1), LPromise.Await);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPromiseTimeout<Integer>);
  TDUnitX.RegisterTestFixture(TTestPromiseTimeout<Boolean>);
  TDUnitX.RegisterTestFixture(TTestPromiseTimeout<String>);
  TDUnitX.RegisterTestFixture(TTestPromiseTimeout<TSimpleRecord>);
  TDUnitX.RegisterTestFixture(TTestPromiseTimeout<TMyObject>);

end.
