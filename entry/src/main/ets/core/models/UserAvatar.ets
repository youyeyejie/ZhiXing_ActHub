export class UserAvatarConfig {
  kind: string = 'default';
  path: string = '';
  scale: number = 1;
  offsetX: number = 0;
  offsetY: number = 0;
}

export class UserAvatarCodec {
  static readonly DEFAULT_AVATAR: string = '{"kind":"default"}';

  static encode(config: UserAvatarConfig): string {
    return JSON.stringify({
      kind: config.kind,
      path: config.path,
      scale: config.scale,
      offsetX: config.offsetX,
      offsetY: config.offsetY,
    });
  }

  static decode(rawValue: string): UserAvatarConfig {
    const config: UserAvatarConfig = new UserAvatarConfig();
    const raw: string = `${rawValue}`.trim();
    if (raw.length === 0) {
      return config;
    }

    try {
      const parsed: Record<string, Object> = JSON.parse(raw);
      config.kind = `${parsed.kind ?? 'default'}`;
      config.path = `${parsed.path ?? ''}`;
      config.scale = UserAvatarCodec.normalizeScale(Number(parsed.scale ?? 1));
      config.offsetX = UserAvatarCodec.normalizeOffset(Number(parsed.offsetX ?? 0));
      config.offsetY = UserAvatarCodec.normalizeOffset(Number(parsed.offsetY ?? 0));
      if (config.kind !== 'image' || config.path.trim().length === 0) {
        config.kind = 'default';
        config.path = '';
      }
      return config;
    } catch (_error) {
      config.kind = 'default';
      return config;
    }
  }

  static normalizeScale(value: number): number {
    if (isNaN(value)) {
      return 1;
    }
    return Math.min(3, Math.max(1, value));
  }

  static normalizeOffset(value: number): number {
    if (isNaN(value)) {
      return 0;
    }
    return Math.min(80, Math.max(-80, value));
  }
}
