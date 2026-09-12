unit Next.Core.Promises.Cancellation;

interface

uses
  System.SysUtils, System.SyncObjs,
  Next.Core.Promises.Exceptions;

type
  /// <summary>
  /// A read-only token that can be checked for cancellation.
  /// Passed into promise chains and long-running operations for cooperative cancellation.
  /// </summary>
  ICancellationToken = interface
    ['{F7A3D8E1-2B4C-4D6F-9E1A-3C5B7D9F0A2E}']
    /// <summary>
    /// Returns True if cancellation has been requested.
    /// </summary>
    function IsCancelled: Boolean;
    /// <summary>
    /// Raises EOperationCancelled if cancellation has been requested.
    /// Call this periodically inside long-running operations for cooperative cancellation.
    /// </summary>
    procedure ThrowIfCancelled;
  end;

  /// <summary>
  /// A source that can trigger cancellation of an associated token.
  /// Create a TCancellationTokenSource, pass its Token to promises, and call Cancel when needed.
  /// </summary>
  ICancellationTokenSource = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    /// <summary>
    /// Returns the cancellation token associated with this source.
    /// </summary>
    function Token: ICancellationToken;
    /// <summary>
    /// Signals cancellation. All tokens derived from this source will report IsCancelled = True.
    /// This operation is thread-safe and idempotent.
    /// </summary>
    procedure Cancel;
    /// <summary>
    /// Returns True if Cancel has been called.
    /// </summary>
    function IsCancelled: Boolean;
  end;

  /// <summary>
  /// Implementation of ICancellationTokenSource and ICancellationToken.
  /// Uses TInterlocked for thread-safe cancellation signalling.
  /// </summary>
  TCancellationTokenSource = class(TInterfacedObject, ICancellationTokenSource, ICancellationToken)
  private
    FCancelled: Integer; // 0 = not cancelled, 1 = cancelled
    function IsCancelled: Boolean;
    procedure ThrowIfCancelled;
    function Token: ICancellationToken;
    procedure Cancel;
  end;

implementation

{ TCancellationTokenSource }

procedure TCancellationTokenSource.Cancel;
begin
  TInterlocked.CompareExchange(FCancelled, 1, 0);
end;

function TCancellationTokenSource.IsCancelled: Boolean;
begin
  Result := TInterlocked.CompareExchange(FCancelled, 0, 0) = 1;
end;

procedure TCancellationTokenSource.ThrowIfCancelled;
begin
  if IsCancelled then
    raise EOperationCancelled.Create;
end;

function TCancellationTokenSource.Token: ICancellationToken;
begin
  Result := Self;
end;

end.
