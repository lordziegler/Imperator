# Ricing de niri — informe de reparación

**Fecha:** 11 de julio de 2026
**Equipo:** Landsraad (portátil, Intel, wifi `wlan0`, ethernet `eno1`)

---

## TL;DR

El night light nunca había funcionado, y la causa resultó ser un patrón que se repetía por todo el repo: **archivos correctamente escritos que nadie había desplegado nunca**. Además encontré cuatro atajos de teclado muertos, un gestor de portapapeles que no sobrevivía a un reinicio, y un módulo de waybar que llevaba desde siempre leyendo una carpeta inexistente.

Todo eso está arreglado. Queda **un paso pendiente que debes ejecutar tú** (ver [Lo que falta](#lo-que-falta)).

---

## 1. El bug original: wlsunset

**Síntoma:** el night light no se activaba nunca.

**Causa raíz:** `wlsunset` no era un bug de wlsunset. Lanzado a mano funcionaba perfecto (detectaba los dos monitores, calculaba la trayectoria solar, aplicaba el gamma). El problema era que **el servicio nunca existió**:

- `Arrakis-sunset/wlsunset.service` estaba escrito, correcto y versionado en tu repo.
- `Impr-niri/autostart.kdl:18` decía *"Night light — manejado por systemd user service"*.
- Pero nadie había ejecutado el paso de despliegue que el propio `Arrakis-sunset/README.md` documenta.
- Resultado: `systemctl --user status wlsunset.service` → **"Unit could not be found"**.

El comentario describía una realidad que no existía.

**Arreglo:** desplegado como symlink a `~/.config/systemd/user/` y habilitado. Ahora aplica 3000 K al anochecer.

---

## 2. La causa raíz *real*: la regla que nadie ejecutaba

Tu repo **codifica** la regla en tres READMEs distintos:

> *"Los daemons van a systemd, los one-shots van a autostart.kdl."*

Pero **nada la ejecutaba**. No había script de despliegue. Cada unit nuevo dependía de que alguien recordara enlazarlo a mano — y no se recordó. `wlsunset.service` llevaba meses así. `waybar-vault.service` tenía exactamente el mismo problema.

**Arreglo — `Arrakis-sunset/deploy.sh` (nuevo):** un único script idempotente que enlaza y habilita *todos* los units del repo. Relánzalo cada vez que añadas uno:

```bash
bash ~/Projects/Imperator-dotfiles/Arrakis-sunset/deploy.sh
```

Esta es la pieza que impide que el bug vuelva.

---

## 3. Servicios activados

Los seis, todos `enabled` (arrancan solos en cada sesión):

| Servicio | Qué hace | Estado |
|---|---|---|
| `wlsunset.service` | Night light, 3000 K | ✅ ya existía, **desplegado** |
| `swayidle.service` | Bloqueo a los 5 min · pantallas off a los 10 · bloqueo antes de suspender | 🆕 **nuevo** |
| `swayosd.service` | OSD en pantalla de volumen/brillo/BloqMayús | 🆕 **nuevo** |
| `polkit-agent.service` | Diálogos gráficos de contraseña | 🆕 **nuevo** |
| `copyq.service` | Portapapeles | 🆕 **nuevo** |
| `waybar-vault.service` | Refresca el módulo del vault de Obsidian | ✅ existía, **desplegado** (pendiente del paso 2) |

### Detalles que importan

**`polkit-agent`** — Tenías `polkit-gnome` **instalado pero nadie lo lanzaba**. `polkitd` (el daemon del sistema) pedía autenticación y no había nadie escuchando: los diálogos de contraseña (montar discos, GParted, actualizaciones gráficas) **fallaban en silencio**. Ahora hay agente.

**`copyq`** — Estaba corriendo, pero **lo habías lanzado a mano**. No estaba en `autostart.kdl` ni en el autostart XDG: al primer reinicio lo habrías perdido. Ahora es un servicio.

> Ojo con un detalle: el unit usa `ExecStart=/usr/bin/copyq` **sin argumentos**, no `--start-server`. Con `--start-server` copyq se bifurca al fondo y el padre sale, así que systemd daba el servicio por muerto y dejaba el servidor huérfano. Sin argumentos, copyq levanta el servidor en primer plano, que es lo que `Type=simple` necesita.

---

## 4. Atajos de teclado que estaban muertos

Tu `binds.kdl` invocaba **binarios que no estaban instalados**. Estos atajos no hacían absolutamente nada:

| Atajo | Necesitaba | Estado |
|---|---|---|
| `Super+Alt+L` — bloquear pantalla | `swaylock` | ✅ instalado |
| Teclas de brillo | `brightnessctl` | ✅ instalado |
| `Shift+Print` — captura con anotación | `grim`, `slurp`, `satty` | ✅ instalados |
| `Mod+Shift+G` — grabar pantalla | `wf-recorder`, `slurp` | ✅ instalados |

*(Tus otros tres atajos de captura — `Print`, `Ctrl+Print`, `Alt+Print` — usan el screenshot **nativo** de niri y siempre funcionaron.)*

---

## 5. Volumen y brillo: ahora se ven

**Antes:** las teclas de volumen funcionaban (vía `wpctl`), pero **a ciegas** — pulsabas y no aparecía nada en pantalla. Las de brillo directamente no funcionaban.

**Ahora:** ambas pasan por `swayosd-client`, que cambia el valor **y** dibuja la barra flotante. También muestra el aviso de Bloq Mayús (esto último necesita el paso 2).

**Cambios en `binds.kdl`:**
```kdl
XF86AudioRaiseVolume  → swayosd-client --output-volume raise
XF86AudioLowerVolume  → swayosd-client --output-volume lower
XF86AudioMute         → swayosd-client --output-volume mute-toggle
XF86AudioMicMute      → swayosd-client --input-volume mute-toggle
XF86MonBrightnessUp   → swayosd-client --brightness raise
XF86MonBrightnessDown → swayosd-client --brightness lower
```

---

## 6. Waybar: mezclador y wifi

Corrección a un diagnóstico mío que era erróneo: **tu waybar sí tenía** módulos de red, bluetooth y volumen. Están dentro del drawer `group/vitals`, ocultos tras el asa (≡), y por eso no los vi al principio.

**Volumen** (`pulseaudio`):
- Clic izquierdo → **`pwvucontrol`** (antes `pavucontrol`). Mezclador nativo de PipeWire en GTK4, moderno y con volumen por aplicación.
- Clic derecho → **mute** (nuevo).
- Scroll → volumen ±5 % (ya funcionaba).

**Wifi** (`network`):
- Clic izquierdo → **`impala`** en una kitty flotante (antes `nm-connection-editor`).
- El módulo lee del kernel vía netlink, **no** de NetworkManager, así que sigue funcionando aunque NM desaparezca.

**Nuevas window-rules en `rules.kdl`** para que ambas ventanas salgan flotantes y centradas (`impala-tui` y `com.saivert.pwvucontrol`).

---

## 7. El bug del vault de Obsidian

Este no lo buscaba, apareció solo.

**Tu vault real se llama `Cerebrum-Secundum`** (con guion). **Siete ficheros** del repo usaban `Cerebrum_Secundum` (con guion bajo):

```
Spicebar/config.jsonc
Spicebar/scripts/otium.sh
Spicebar/scripts/vault-watch.sh
Spicebar/scripts/calcurse-open.sh
Spicebar/scripts/mentat-click.sh
Spicebar/scripts/mentat-next.sh
Spicebar/scripts/mentat-prev.sh
```

**Consecuencia:** tu módulo `otium` de waybar llevaba **desde siempre** mostrando "Nulla officia" (sin tareas) — no porque no tuvieras tareas, sino porque leía una carpeta que no existe. Y los clics que abren Obsidian apuntaban a un vault inexistente.

**Arreglo:** corregido en los 7 ficheros. Verificado contra `~/.config/obsidian/obsidian.json`, donde el vault está registrado como `/home/ziegler/Documents/Cerebrum-Secundum`.

*(Ahora mismo `otium` sigue diciendo "Nulla officia", pero eso ya es **correcto**: no tienes tareas `- [ ]` pendientes en el vault.)*

Y un segundo bug en el mismo servicio: `vault-watch.sh` llama a `inotifywait`, y **`inotify-tools` no estaba instalado** — por eso el servicio arrancaba y moría en 200 ms sin vigilar nada. Se instala en el paso 2.

---

## 8. Bloqueo de pantalla

**`swaylock` configurado** en tu paleta Arrakis (`Impr-lock/config`, enlazado a `~/.config/swaylock`):

- Fondo: el backdrop del overview de niri.
- Anillo: **oro apagado** en reposo → **oro brillante** al escribir → **rojo** al fallar.
- Indicador de Bloq Mayús.

**`swayidle`** (nuevo servicio): bloquea a los 5 min, apaga las pantallas a los 10, y bloquea **antes de suspender** — para que no despiertes con la sesión abierta.

---

## 9. Otras piezas instaladas

| Paquete | Por qué |
|---|---|
| `wl-clipboard` | No tenías ni `wl-copy`/`wl-paste`. Necesarios para scripts y para la CLI. |
| `xdg-desktop-portal-gnome` | Solo tenías el portal `-gtk`. **Sin esto, compartir pantalla en Discord/Zoom/navegador no funciona en niri.** |
| `qt6-wayland` / `qt5-wayland` | Faltaban. Tus apps Qt caían a XWayland (borrosas, sin escalado nativo) — no rotas, pero degradadas. Tu `QT_QPA_PLATFORM "wayland;xcb"` las salvaba con el fallback. |

*(No instalé `cliphist`: ya tienes **CopyQ**, que hace lo mismo y mejor.)*

---

## Lo que falta

**Ejecuta el paso 2.** Es el único que queda, y es el que toca la red:

```bash
sudo bash ~/Documents/paso2-migrar-red.sh
```

Hace tres cosas:

1. Instala `inotify-tools` → arregla `waybar-vault.service`.
2. Activa `swayosd-libinput-backend` → habilita el OSD de Bloq Mayús.
3. **Migra la red de `wpa_supplicant` a `iwd`** (para que impala funcione de verdad).

### Sobre la migración de red

Elegiste **iwd puro**, así que:

- **NetworkManager y wpa_supplicant quedan desactivados.**
- **`iwd`** autentica el wifi. **`systemd-networkd`** hace el DHCP — de wifi *y de cable*, para que no pierdas el ethernet al desaparecer NM. **`systemd-resolved`** sigue con el DNS (ya lo tenías activo).
- Tus contraseñas wifi se copian de los perfiles de NM al formato de iwd automáticamente. No tendrás que reintroducirlas (salvo que alguna esté guardada en el keyring en vez de en disco — el script te avisará).
- **Pierdes:** `nm-connection-editor`, el soporte de VPN de NetworkManager, y los portales cautivos se vuelven más incómodos.

### Si te quedas sin red

El rollback ya está escrito y **no necesita internet** (NetworkManager sigue instalado y tus perfiles no se borran):

```bash
sudo bash ~/Documents/rollback-red.sh
```

También puedes conectar a mano con `impala`.

---

---

# ADENDA — El incidente de red (11 jul, noche)

## Qué pasó

El paso 2 migró la red a iwd, **iwd no logró autenticarse**, y te quedaste sin internet un buen rato. Ejecutaste el rollback (bien hecho), pero **iwd volvió solo 47 segundos después**: tiene **activación por D-Bus**, así que basta con que algo lo llame — abrir `impala`, o el clic del icono de wifi que yo mismo te había configurado — para que resucite y se pelee con NetworkManager por la interfaz. Mi rollback original no lo enmascaraba. **Era un bug mío.**

## Por qué falló iwd de verdad

**No** fue el formato de las contraseñas (esa fue mi primera hipótesis y el diagnóstico la descartó: passphrases de 11 chars, `psk-flags=0`, ficheros `.psk` correctos).

La causa real es tu hardware: **Realtek RTL8821CE, driver `rtw88`**. Hay una regresión conocida del kernel (en `mac80211`) por la que los paquetes EAPOL no llegan al router usando el método nuevo, y **el handshake WPA2 de 4 vías falla con iwd pero funciona con wpa_supplicant**. Eso es exactamente lo que viste: NetworkManager conectaba, iwd daba `connect-failed, status: 1`.

El workaround documentado es `ControlPortOverNL80211=false` en `/etc/iwd/main.conf`. Sin eso, iwd **iba a fallar siempre** en tu portátil.

## Estado tras el rescate

| | |
|---|---|
| Conexión | ✅ NetworkManager en `wlan0`, con ruta |
| iwd | enmascarado (no puede resucitar) |
| systemd-networkd | apagado |
| `/etc/systemd/network/` | vacío |
| impala | **desinstalado** (lo quitaste tú) |
| Bloq Mayús molesto | ✅ desactivado (`swayosd-libinput-backend`) |
| DNS | ✅ funciona (ver nota abajo) |

**Nota sobre el DNS:** no está roto y **yo no lo rompí**. Pero descubrí que **el servidor DNS de tu router (192.168.1.1) no responde**, así que cada consulta nueva tarda ~6 segundos hasta que `systemd-resolved` cae a sus servidores de reserva. Es un problema tuyo preexistente, ajeno a todo esto. Se arregla configurando un DNS fiable — dímelo y lo hago.

## Reparado

- **El botón de wifi de waybar estaba muerto**: apuntaba fijo a `impala`, que ya no existe. Ahora llama a `Spicebar/scripts/wifi-menu.sh`, que **detecta qué backend manda** y abre impala (si iwd) o nm-connection-editor (si NM). Nunca más un botón muerto, gobierne quien gobierne.
- **Restaurada la window-rule de `nm-connection-editor`** en `rules.kdl`, que yo había borrado dando por hecho que NM desaparecería.
- **Rollback reescrito**: ahora **enmascara** iwd, que es lo único que impide la resurrección por D-Bus.

## DESENLACE — iwd funciona (12 jul, 23:40)

El reintento con `ControlPortOverNL80211=false` **conectó a la primera**. El diagnóstico del chip era correcto.

| | Antes | Ahora |
|---|---|---|
| Backend | NetworkManager | **iwd** (permanente) |
| Red | MAYITO_IDN (2.4 GHz) | **MAYITO_IDN_5G** (5 GHz, 802.11ac, 433 Mbit/s, −42 dBm) |
| DNS | ~6000 ms por consulta | **226 ms** |
| impala | no funcionaba | ✅ funciona (clic en el icono de wifi) |

### El hallazgo colateral: tu red bloquea el DNS por UDP

Investigando el DNS lento descubrí que **tu red descarta todo el tráfico DNS por UDP/53** — el router, Cloudflare, Quad9 y Google, todos. Pero **todos responden por TCP**. `systemd-resolved` intentaba UDP, esperaba ~5 s a que expirara y solo entonces reintentaba por TCP: de ahí los 6 segundos por consulta.

**Esto ya te pasaba con NetworkManager.** No lo causó iwd ni el incidente; simplemente nadie lo había diagnosticado.

**Solución aplicada:** DNS-over-TLS (TCP/853, verificado abierto) contra Cloudflare + Quad9, en `/etc/systemd/resolved.conf.d/dns-over-tls.conf`. Esquiva el bloqueo de raíz y de paso te cifra el DNS. **De 6000 ms a 226 ms.**

> ⚠ Único inconveniente: en un **portal cautivo** (wifi de hotel/aeropuerto) el DoT estricto puede impedir que cargue la página de login. Si te pasa, desactívalo temporalmente:
> ```bash
> sudo rm /etc/systemd/resolved.conf.d/dns-over-tls.conf
> sudo systemctl restart systemd-resolved
> ```

### Estado del arranque (ya coherente)

`iwd` enabled · `NetworkManager` disabled (pero **instalado**, el rollback siempre existe) · `systemd-networkd` cubre el ethernet · `systemd-resolved` con DoT.

## Historial: cómo se reintentó iwd + impala

Ahora es **seguro**, porque el sistema se repara solo:

```bash
sudo bash ~/Documents/paso4-iwd-seguro.sh
```

Lo que cambia respecto al intento que te dejó tirado:

1. **Rollback automático.** Antes de tocar la red, arma un temporizador que restaura NetworkManager **en 5 minutos pase lo que pase**. Si iwd falla y no puedes hacer nada, la máquina se arregla sola. **No te puedes quedar tirado.**
2. **El arreglo real**: `ControlPortOverNL80211=false` — sin esto volvería a fallar igual.
3. Migra **todas** tus redes, incluida `MAYITO_IDN` (la 2.4 GHz a la que te reconectaste en el rescate). El intento anterior no la tenía.
4. iwd hace su propio DHCP: una pieza móvil menos.
5. Log de depuración activado: si vuelve a fallar, sabremos exactamente por qué.

Si conecta y lo pruebas y va bien, lo haces permanente con `sudo bash ~/Documents/confirmar-iwd.sh` (eso también cubre el ethernet con systemd-networkd, que iwd no gestiona). **Si no haces nada, vuelve NetworkManager solo.**

---

## Ficheros tocados

Todo está en `~/Projects/Imperator-dotfiles`, **sin commitear** — revísalo con `git diff` y `git status`.

**Nuevos:**
```
Arrakis-sunset/deploy.sh            ← la pieza clave
Arrakis-sunset/swayidle.service
Arrakis-sunset/swayosd.service
Arrakis-sunset/polkit-agent.service
Arrakis-sunset/copyq.service
Impr-lock/config                    ← swaylock (nuevo directorio)
```

**Modificados:**
```
Impr-niri/binds.kdl        volumen y brillo → swayosd
Impr-niri/rules.kdl        window-rules de impala y pwvucontrol
Impr-niri/autostart.kdl    documentados los servicios; quitado el swayidle comentado
Spicebar/config.jsonc      pwvucontrol, mute, impala, ruta del vault
Spicebar/scripts/*.sh      ruta del vault (6 scripts)
zardaukar-sh/zshrc         PATH duplicado (ver abajo)
zardaukar-sh/exports.zsh   PATH duplicado
```

**Enlaces creados:**
```
~/.config/swaylock            → Impr-lock/
~/.config/systemd/user/*.service  → los 6 units
```

### Nota aparte: el `$PATH` duplicado

Sin relación con el ricing, pero lo encontré de camino: `~/.local/bin` aparecía **dos veces** en tu `$PATH`. Dos ficheros lo anteponían sin comprobar si ya estaba (`zardaukar-sh/exports.zsh:3` y la línea que metió el instalador de Antigravity en `zardaukar-sh/zshrc:63`). Ambos llevan ahora una guarda `case`. Inofensivo, pero se multiplicaba en cada shell anidado.
