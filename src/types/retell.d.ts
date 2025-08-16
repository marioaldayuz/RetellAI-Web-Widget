declare module 'retell-client-js-sdk' {
  export interface StartCallOptions {
    accessToken: string;
  }

  export class RetellWebClient {
    constructor();
    
    startCall(options: StartCallOptions): Promise<void>;
    stopCall(): void;
    mute(): void;
    unmute(): void;
    
    on(event: 'call_started', callback: () => void): void;
    on(event: 'call_ended', callback: () => void): void;
    on(event: 'agent_start_talking', callback: () => void): void;
    on(event: 'agent_stop_talking', callback: () => void): void;
    on(event: 'error', callback: (error: any) => void): void;
  }
}
