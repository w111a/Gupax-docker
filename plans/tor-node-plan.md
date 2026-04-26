# Tor Node Investigation — Phase 0 Findings

## Critical Discovery: monerod Config File Location

monerod reads its config from: `~/.bitmonero/bitmonero.conf`

In the container this resolves to: `/home/miner/.bitmonero/bitmonero.conf`

**However:** the `/home/miner/.bitmonero` directory is in an **anonymous Docker volume** (owned by root, not bind-mounted from host). The miner user **cannot write to it**.

### Volume Layout (Current)

```
Host bind mount (host):    /path/to/gupax-monero/
                           └── p2pool/     (Gupax app data)
                           └── node/        (monerod LMDB db)

Anonymous Docker volume:    /home/miner/.bitmonero/   ← monerod config + blockchain
Anonymous Docker volume:    /home/miner/.local/share/gupax/   ← Gupax state
```

**Problem:** To use `bitmonero.conf` for Tor settings, we'd need to either:
1. Bind-mount the host's `.bitmonero` directory (breaks blockchain sync if not already synced)
2. Use monerod CLI args (Gupax doesn't expose `--proxy`)

---

## How Gupax Launches monerod (Source Code Analysis)

From `gupax-io/gupax/src/helper/node.rs`:

```rust
pub fn start_node(node: &Node, data_dir: &Path) -> Result<Option<DaemonHandle>> {
    let mut cmd = Command::new(monerod_path);
    cmd.arg(format!("--data-dir={}", data_dir.display()));
    // ...
    if !node.arguments.is_empty() {
        for arg in node.arguments.split_whitespace() {
            cmd.arg(arg);   // ← Custom CLI args from [node].arguments in state.toml
        }
    }
    // ...
}
```

**Key insight:** Gupax passes `node.arguments` (from `state.toml`) directly as CLI args to monerod.

The `[node]` section of `state.toml` has an `arguments` field — currently empty.

### Workaround: Use state.toml to inject --proxy

Since `node.arguments` → monerod CLI args, we can:
1. Set `arguments = "--proxy=127.0.0.1:9050"` in state.toml
2. monerod routes traffic through Tor SOCKS proxy
3. No Gupax source code changes needed!

**But:** This requires the user to edit `state.toml` manually, or we provide a startup script that patches it.

---

## Implementation Options

### Option A: tor in-container (Recommended for MVP)

**Approach:**
- Add `tor` package to Dockerfile
- Start tor in `start.sh` when `TOR_ENABLED=true`
- Wait for tor SOCKS port before starting Gupax
- Use Gupax UI "Node → arguments" field: `--proxy=127.0.0.1:9050`
- Or: pre-populate `state.toml` with default Tor arguments via a startup patch

**Pros:** Single container, simplest for users
**Cons:** +30-40MB image size
**Feasibility:** ✅ High — no Gupax changes needed

### Option B: tor sidecar (compose)

**Approach:**
- `torproxy` container on same Docker network
- monerod connects to `torproxy:9050`
- Gupax container has no tor installed

**Pros:** Cleaner separation, tor upgradeable independently
**Cons:** More complex compose setup
**Feasibility:** ✅ High

### Option C: Host Tor

**Approach:**
- User runs tor on Unraid host
- Gupax container connects to `host.docker.internal:9050`

**Pros:** No container changes
**Cons:** Requires Unraid host tor setup, Unraid-specific
**Feasibility:** ⚠️ Medium — Unraid-specific

---

## Recommended Implementation Path

### Phase 1: In-container Tor (MVP)

1. **Dockerfile changes:**
   - Add `tor` to apt install list
   - OR use `torsocks` + `tor` package

2. **start.sh changes:**
   ```bash
   if [ "$TOR_ENABLED" = "true" ]; then
       echo "[*] Starting Tor daemon..."
       tor &
       TOR_PID=$!
       # Wait for SOCKS port to be ready
       for i in $(seq 1 30); do
           nc -z 127.0.0.1 9050 && break
           sleep 1
       done
   fi
   ```

3. **User documentation:**
   - Set `TOR_ENABLED=true` in Unraid template
   - In Gupax UI: Node tab → Arguments field: `--proxy=127.0.0.1:9050`

### Phase 2: Hidden Service Support

- Add `--anonymous-inbound` for inbound Tor connections
- Generate `.onion` address and display in Gupax UI
- Would need startup script to extract `.onion` address from monerod logs

### Phase 3: Full monerod.conf injection

- Generate `/home/miner/.bitmonero/bitmonero.conf` at startup
- More complete than CLI args
- Requires bind-mounting `.bitmonero` from host

---

## Immediate Next Step

**Test if `--proxy` argument actually works:**
1. In Gupax UI → Node tab → Arguments: `--proxy=127.0.0.1:9050`
2. Start node
3. Check monerod logs for Tor connection evidence

But since tor isn't installed in the container yet, this won't work without `TOR_ENABLED=true`.

**Alternative test:** Verify monerod accepts the `--proxy` arg without error by checking `ps aux` in the container.

---

## Risks & Blockers

| Risk | Severity | Mitigation |
|------|----------|------------|
| Gupax doesn't expose proxy settings in UI | ⚠️ Medium | Use `state.toml` patch or CLI args |
| `.bitmonero` volume is anonymous (root-owned) | ✅ Workaround | Bind-mount from host or patch state.toml |
| monerod Tor traffic still leaks DNS on some configs | ⚠️ Medium | Use `--proxy-allow-dns-leaks=no` |
| Latency impact on blockchain sync | Low | Not user-facing, just initial sync |
