unit Next.Core.Promises.Exceptions;

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  /// <summary>
  /// Exception raised when an operation exceeds the specified timeout duration.
  /// Used by IPromise&lt;T&gt;.Timeout to signal that a promise did not settle in time.
  /// </summary>
  ETimeoutException = class(Exception)
  public
    constructor Create; overload;
    constructor Create(const AMessage: string); overload;
  end;

  /// <summary>
  /// Exception raised when a cancelled operation is detected.
  /// Used by the cancellation token system to signal cooperative cancellation.
  /// </summary>
  EOperationCancelled = class(Exception)
  public
    constructor Create; overload;
    constructor Create(const AMessage: string); overload;
  end;

  /// <summary>
  /// Exception that aggregates multiple exceptions into a single exception object.
  /// Used by Promise.Any when all promises reject — contains all individual rejection exceptions.
  /// The EAggregateException owns the exception objects it holds and frees them on destruction.
  /// </summary>
  EAggregateException = class(Exception)
  private
    FExceptions: TArray<Exception>;
  public
    constructor Create(const AExceptions: TArray<Exception>);
    destructor Destroy; override;
    /// <summary>
    /// The array of inner exceptions. The EAggregateException owns these objects.
    /// </summary>
    property Exceptions: TArray<Exception> read FExceptions;
  end;

implementation

{ ETimeoutException }

constructor ETimeoutException.Create;
begin
  inherited Create('Promise timed out');
end;

constructor ETimeoutException.Create(const AMessage: string);
begin
  inherited Create(AMessage);
end;

{ EOperationCancelled }

constructor EOperationCancelled.Create;
begin
  inherited Create('Operation was cancelled');
end;

constructor EOperationCancelled.Create(const AMessage: string);
begin
  inherited Create(AMessage);
end;

{ EAggregateException }

constructor EAggregateException.Create(const AExceptions: TArray<Exception>);
var
  LMsg: string;
  i: Integer;
begin
  LMsg := 'All promises were rejected (';
  for i := Low(AExceptions) to High(AExceptions) do
  begin
    if i > Low(AExceptions) then
      LMsg := LMsg + ', ';
    if Assigned(AExceptions[i]) then
      LMsg := LMsg + AExceptions[i].Message
    else
      LMsg := LMsg + '<nil>';
  end;
  LMsg := LMsg + ')';

  inherited Create(LMsg);
  FExceptions := AExceptions;
end;

destructor EAggregateException.Destroy;
var
  i: Integer;
begin
  for i := Low(FExceptions) to High(FExceptions) do
    FreeAndNil(FExceptions[i]);
  inherited;
end;

end.
