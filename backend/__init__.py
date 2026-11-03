import sys
from pathlib import Path

# Permet l'import direct des modules du dossier backend
_backend_dir = str(Path(__file__).resolve().parent)
if _backend_dir not in sys.path:
    sys.path.insert(0, _backend_dir)
