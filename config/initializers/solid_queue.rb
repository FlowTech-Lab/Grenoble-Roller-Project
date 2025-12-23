# Configuration for Solid Queue
# Solid Queue utilise SQLite séparé (configuré dans database.yml)
# ⚠️  IMPORTANT : La queue SQLite est complètement séparée de PostgreSQL
#    - Les jobs en queue restent intacts lors des opérations PostgreSQL
#    - Le fichier SQLite est dans storage/solid_queue.sqlite3

# Solid Queue détecte automatiquement la configuration queue dans database.yml
# La configuration explicite se fait dans config/environments/*.rb avec :
# config.solid_queue.connects_to = { database: { writing: :queue, reading: :queue } }
