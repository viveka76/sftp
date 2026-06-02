log_info()  { echo "$(date '+%F %T') [INFO]  $*"; }
log_warn()  { echo "$(date '+%F %T') [WARN]  $*"; }
log_error() { echo "$(date '+%F %T') [ERROR] $*" >&2; }