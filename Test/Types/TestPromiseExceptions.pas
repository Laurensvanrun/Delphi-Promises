unit TestPromiseExceptions;

interface

uses
  DUnitX.TestFramework, System.SysUtils,
  Next.Core.Promises.Exceptions;

type
  [TestFixture]
  TTestPromiseExceptions = class
  public
    [Test]    procedure ETimeoutExceptionDefaultMessage;
    [Test]    procedure ETimeoutExceptionCustomMessage;
    [Test]    procedure EOperationCancelledDefaultMessage;
    [Test]    procedure EOperationCancelledCustomMessage;
    [Test]    procedure EAggregateExceptionCreation;
    [Test]    procedure EAggregateExceptionExceptionsProperty;
    [Test]    procedure EAggregateExceptionDestroyFreesInner;
    [Test]    procedure EAggregateExceptionWithNilInArray;
    [Test]    procedure EAggregateExceptionEmptyArray;
  end;

implementation

{ TTestPromiseExceptions }

procedure TTestPromiseExceptions.ETimeoutExceptionDefaultMessage;
var
  E: ETimeoutException;
begin
  E := ETimeoutException.Create;
  try
    Assert.AreEqual('Promise timed out', E.Message);
  finally
    E.Free;
  end;
end;

procedure TTestPromiseExceptions.ETimeoutExceptionCustomMessage;
var
  E: ETimeoutException;
begin
  E := ETimeoutException.Create('custom timeout');
  try
    Assert.AreEqual('custom timeout', E.Message);
  finally
    E.Free;
  end;
end;

procedure TTestPromiseExceptions.EOperationCancelledDefaultMessage;
var
  E: EOperationCancelled;
begin
  E := EOperationCancelled.Create;
  try
    Assert.AreEqual('Operation was cancelled', E.Message);
  finally
    E.Free;
  end;
end;

procedure TTestPromiseExceptions.EOperationCancelledCustomMessage;
var
  E: EOperationCancelled;
begin
  E := EOperationCancelled.Create('custom cancel');
  try
    Assert.AreEqual('custom cancel', E.Message);
  finally
    E.Free;
  end;
end;

procedure TTestPromiseExceptions.EAggregateExceptionCreation;
var
  E: EAggregateException;
begin
  E := EAggregateException.Create([
    Exception.Create('alpha'),
    Exception.Create('beta')
  ]);
  try
    Assert.IsTrue(E.Message.Contains('alpha'));
    Assert.IsTrue(E.Message.Contains('beta'));
  finally
    E.Free;
  end;
end;

procedure TTestPromiseExceptions.EAggregateExceptionExceptionsProperty;
var
  E: EAggregateException;
begin
  E := EAggregateException.Create([
    Exception.Create('first'),
    Exception.Create('second'),
    Exception.Create('third')
  ]);
  try
    Assert.AreEqual(3, Length(E.Exceptions));
    Assert.AreEqual('first', E.Exceptions[0].Message);
    Assert.AreEqual('second', E.Exceptions[1].Message);
    Assert.AreEqual('third', E.Exceptions[2].Message);
  finally
    E.Free;
  end;
end;

procedure TTestPromiseExceptions.EAggregateExceptionDestroyFreesInner;
var
  E: EAggregateException;
begin
  // Just verify that destruction does not raise
  E := EAggregateException.Create([
    Exception.Create('inner1'),
    Exception.Create('inner2')
  ]);
  E.Free; // Should free inner exceptions without error
  Assert.IsTrue(True); // If we get here, destruction succeeded
end;

procedure TTestPromiseExceptions.EAggregateExceptionWithNilInArray;
var
  E: EAggregateException;
begin
  E := EAggregateException.Create([
    Exception.Create('real'),
    nil
  ]);
  try
    Assert.IsTrue(E.Message.Contains('<nil>'));
    Assert.IsTrue(E.Message.Contains('real'));
    Assert.AreEqual(2, Length(E.Exceptions));
  finally
    E.Free;
  end;
end;

procedure TTestPromiseExceptions.EAggregateExceptionEmptyArray;
var
  E: EAggregateException;
begin
  E := EAggregateException.Create([]);
  try
    Assert.AreEqual('All promises were rejected ()', E.Message);
    Assert.AreEqual(0, Length(E.Exceptions));
  finally
    E.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPromiseExceptions);

end.
