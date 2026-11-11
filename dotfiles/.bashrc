# Timestamps for history command
export HISTTIMEFORMAT='%F %t '
export PATH="$PATH:/opt/mssql-tools18/bin"
. "$HOME/.cargo/env"
# X-CMD (installer can't write to the read-only HM-managed ~/.bashrc)
[ ! -f "$HOME/.x-cmd.root/X" ] || . "$HOME/.x-cmd.root/X"
