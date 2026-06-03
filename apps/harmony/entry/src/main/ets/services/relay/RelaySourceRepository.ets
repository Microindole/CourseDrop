import { appPreferencesStore } from '../../common/AppPreferencesStore';
import { RelayServerConfig } from '../../models/RelayServerConfig';

const KEY_RELAY_SERVERS: string = 'relay.servers';
const OFFICIAL_RELAY_ID: string = 'relay-official-coursedrop';
const OFFICIAL_RELAY_NAME: string = 'CourseDrop 官方中转源';
const OFFICIAL_RELAY_URL: string = 'https://coursedrop.microindole.me';

export interface RelaySourceRepository {
  list(): RelayServerConfig[];
  save(server: RelayServerConfig): void;
  remove(id: string): void;
}

export class LocalRelaySourceRepository implements RelaySourceRepository {
  private relayServers: RelayServerConfig[] = [];

  list(): RelayServerConfig[] {
    const servers: RelayServerConfig[] = [];
    this.relayServers.forEach((server: RelayServerConfig) => {
      servers.push({
        id: server.id,
        name: server.name,
        url: server.url,
        enabled: server.enabled,
        priority: server.priority
      });
    });
    return servers;
  }

  save(server: RelayServerConfig): void {
    const index = this.relayServers.findIndex((next) => next.id === server.id);
    if (index < 0) {
      this.relayServers.push(server);
      return;
    }
    this.relayServers[index] = server;
  }

  remove(id: string): void {
    this.relayServers = this.relayServers.filter((server) => server.id !== id);
  }
}

export class PreferencesRelaySourceRepository implements RelaySourceRepository {
  private relayServers: RelayServerConfig[] = [];
  private loaded: boolean = false;

  list(): RelayServerConfig[] {
    this.ensureLoaded();
    return this.copyServers(this.relayServers);
  }

  save(server: RelayServerConfig): void {
    this.ensureLoaded();
    const nextServer = this.copyServer(server);
    const index = this.relayServers.findIndex((next) => next.id === server.id);
    if (index < 0) {
      this.relayServers.push(nextServer);
    } else {
      this.relayServers[index] = nextServer;
    }
    this.persist();
  }

  remove(id: string): void {
    this.ensureLoaded();
    this.relayServers = this.relayServers.filter((server) => server.id !== id);
    this.persist();
  }

  private ensureLoaded(): void {
    if (this.loaded) {
      return;
    }
    this.loaded = true;
    const jsonText = appPreferencesStore.getString(KEY_RELAY_SERVERS, '[]');
    try {
      const servers = JSON.parse(jsonText) as RelayServerConfig[];
      this.relayServers = this.copyServers(servers);
    } catch (error) {
      console.error(`[CourseDrop] load relay sources failed: ${String(error)}`);
      this.relayServers = [];
    }
    this.ensureOfficialRelaySource();
  }

  private persist(): void {
    appPreferencesStore.putString(KEY_RELAY_SERVERS, JSON.stringify(this.relayServers));
  }

  private ensureOfficialRelaySource(): void {
    const existing = this.relayServers.find((server: RelayServerConfig) => server.url === OFFICIAL_RELAY_URL);
    if (existing !== undefined) {
      return;
    }
    const official: RelayServerConfig = {
      id: OFFICIAL_RELAY_ID,
      name: OFFICIAL_RELAY_NAME,
      url: OFFICIAL_RELAY_URL,
      enabled: true,
      priority: 1
    };
    this.relayServers.forEach((server: RelayServerConfig) => {
      server.priority += 1;
    });
    this.relayServers.push(official);
    this.persist();
  }

  private copyServers(source: RelayServerConfig[]): RelayServerConfig[] {
    const servers: RelayServerConfig[] = [];
    source.forEach((server: RelayServerConfig) => {
      servers.push(this.copyServer(server));
    });
    return servers;
  }

  private copyServer(server: RelayServerConfig): RelayServerConfig {
    return {
      id: server.id,
      name: server.name,
      url: server.url,
      enabled: server.enabled,
      priority: server.priority
    };
  }
}
