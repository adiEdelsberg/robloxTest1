# Flying Bird NPC System

Folder structure:

- `ServerStorage/FlyingBirdSystem/BirdConfig.luau`: bird definitions, rarity, assets, LOD distances, behavior tuning.
- `ServerStorage/FlyingBirdSystem/Rarity.luau`: rarity colors, ordering, weighted picker.
- `ServerStorage/FlyingBirdSystem/FlightMath.luau`: steering, path, obstacle avoidance helpers.
- `ServerStorage/FlyingBirdSystem/ServerBirdService.luau`: server-side spawning, flocking, behavior state, snapshots.
- `ServerScriptService/FlyingBirds.server.luau`: boots the server service.
- `StarterPlayerScripts/FlyingBirdsClient.client.luau`: client-side visuals, LOD, trails, glow, billboards.

Example bird model setup:

- For high graphics, set `meshId`, `textureId`, and optional `surfaceAppearance` in `BirdConfig`.
- Keep one mesh per bird body for mobile-friendly rendering.
- Wings and tail are procedural client-side parts by default. Replace them with MeshParts in `createBirdVisual` if you have custom wing/tail meshes.
- `wingAnimationId` is reserved in config for rigs that use AnimationControllers. The default implementation uses procedural flapping to avoid rig overhead.

Example spawn zone setup:

- Create `workspace.FlyingBirdSpawnZones`.
- Add transparent anchored Parts.
- Set each part attribute `Radius` to define where birds choose random paths.
- If no zone exists, the service creates an invisible example zone.

Example landing/perch setup:

- Create `workspace.FlyingBirdLandingPoints`.
- Add transparent anchored Parts on roofs, trees, signs, or cliffs.
- Birds can choose these for `Land` behavior.
- If no perches exist, the service creates invisible example perches.

Optimization notes:

- Server only simulates compact bird data and sends snapshots.
- Client creates MeshParts, SurfaceAppearance, trails, glow, labels, wings, and tails.
- Close birds use full animation and effects.
- Mid-distance birds keep simple wing motion.
- Far birds hide effects and eventually cull.
- Mobile gets a lower full-LOD budget.
- All RenderStepped and Heartbeat connections are centralized and old visuals are destroyed after timeout to avoid memory leaks.
