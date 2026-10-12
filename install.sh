#!/bin/bash
# Zentrales Gehirn - Einrichtung fuer macOS (ein Befehl)
# Aufruf im Terminal:
#   curl -fsSL https://raw.githubusercontent.com/derspassvogel911/setup-mac/main/install.sh | bash
# Enthaelt KEINE Zugangsdaten. Anmeldung bei GitHub passiert im Browser.

KONTO="derspassvogel911"
VAULT_REPO="zentrales-gehirn"
VAULT="$HOME/Zentrales_Gehirn"

schritt() { printf "\n\033[36m=== %s ===\033[0m\n" "$1"; }
hat() { command -v "$1" >/dev/null 2>&1; }

schritt "1/6 Programme installieren"
if ! hat brew; then
  echo "Installiere Homebrew (du wirst nach deinem Mac-Passwort gefragt) ..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/tty
fi
# Homebrew in den Pfad aufnehmen (Apple Silicon oder Intel)
if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
if [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi
hat brew || { echo "Homebrew nicht gefunden. Abbruch."; exit 1; }

hat git  || brew install git
hat gh   || brew install gh
hat node || brew install node
if [ ! -d "/Applications/Obsidian.app" ]; then brew install --cask obsidian; else echo "Obsidian ist schon da."; fi

schritt "2/6 Werkzeuge (npm)"
npm install -g defuddle knap @anthropic-ai/claude-code 2>&1 | tail -3

schritt "3/6 Bei GitHub anmelden"
if ! gh auth status >/dev/null 2>&1; then
  echo "Gleich oeffnet sich der Browser. Code eingeben, anmelden, 'Authorize' klicken."
  gh auth login --hostname github.com --git-protocol https --web </dev/tty
fi
gh auth setup-git >/dev/null 2>&1
if [ -z "$(git config --global user.name)" ]; then
  LOGIN=$(gh api user --jq .login); ID=$(gh api user --jq .id); NAME=$(gh api user --jq '.name // empty')
  git config --global user.name "${NAME:-$LOGIN}"
  git config --global user.email "${ID}+${LOGIN}@users.noreply.github.com"
fi

schritt "4/6 Vault holen"
if [ -d "$VAULT/.git" ]; then
  echo "Vault existiert schon unter $VAULT - hole den neuesten Stand."
  git -C "$VAULT" pull
else
  gh repo clone "$KONTO/$VAULT_REPO" "$VAULT"
fi

schritt "5/6 Obsidian-Plugins installieren"
installiere_plugin() {
  id="$1"; repo="$2"; ziel="$VAULT/.obsidian/plugins/$id"
  if [ -f "$ziel/main.js" ]; then echo "$id: schon da."; return; fi
  mkdir -p "$ziel"
  for f in main.js manifest.json styles.css; do
    curl -fsSL "https://github.com/$repo/releases/latest/download/$f" -o "$ziel/$f" || [ "$f" = "styles.css" ] || echo "$id: $f konnte nicht geladen werden."
  done
  echo "$id: installiert."
}
installiere_plugin obsidian-git    Vinzent03/obsidian-git
installiere_plugin realclaudian    YishenTu/claudian
installiere_plugin copilot         logancyang/obsidian-copilot
installiere_plugin terminal        polyipseity/obsidian-terminal
installiere_plugin obsidian42-brat TfTHacker/obsidian42-brat

schritt "6/6 Fertig"
cat <<EOF

Fast geschafft:
 1. Obsidian starten -> "Ordner als Vault oeffnen" -> $VAULT
 2. Einstellungen -> Community-Plugins -> Eingeschraenkten Modus ausschalten und die Plugins aktivieren.
 3. API-Schluessel (Copilot, Claudian) und die Anmeldung bei Claude Code (Befehl: claude) einmal neu eingeben.
 4. Im Plugin "Git": "Pull on startup" einschalten.
Hinweis: "Neural Vault" ist nicht dabei und muss von Hand installiert werden.
Bekannt: Der Skill-Abgleich von Claudian (PowerShell-Hook) laeuft auf dem Mac noch nicht.
EOF
