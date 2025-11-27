#!/bin/bash
# Script temporaire pour vérifier les migrations destructives

CONTAINER_NAME="grenoble-roller-staging"
NEW_MIGRATIONS="20250126180000_add_donation_cents_to_orders.rb 20251117011815_add_image_url_to_product_variants.rb 20251124013654_add_skill_level_to_users.rb 20251124020634_add_confirmable_to_users.rb"
DESTRUCTIVE_PATTERNS_UP="drop_table|remove_column|remove_index|remove_foreign_key|remove_reference|remove_timestamps|remove_belongs_to|change_column_null.*false|execute.*DELETE|execute.*TRUNCATE|execute.*DROP"

echo "=== Vérification migrations destructives (avec statut DB) ==="
echo ""

# Récupérer le statut des migrations dans la DB
MIGRATION_STATUS=$(docker exec "$CONTAINER_NAME" bin/rails db:migrate:status 2>&1 | grep -v "Generating image" | grep -v "Please add" || echo "")

NEW_DESTRUCTIVE_FOUND=false

for mig_file in $NEW_MIGRATIONS; do
    mig_id=$(echo "$mig_file" | cut -d'_' -f1)
    
    if [ -f "db/migrate/$mig_file" ]; then
        echo "📄 $mig_file"
        
        # Vérifier si déjà appliquée dans la DB
        if echo "$MIGRATION_STATUS" | grep -q "^.*up.*$mig_id"; then
            echo "  ✅ DÉJÀ APPLIQUÉE (status: up)"
            echo "  → Pas de risque, migration déjà en production"
        else
            echo "  🆕 NOUVELLE migration (status: down)"
            
            # Vérifier si la méthode up() est destructive
            if grep -qiE "$DESTRUCTIVE_PATTERNS_UP" "db/migrate/$mig_file"; then
                # Vérifier si c'est dans la méthode up() ou down()
                if grep -A 20 "^  def up" "db/migrate/$mig_file" | grep -qiE "$DESTRUCTIVE_PATTERNS_UP"; then
                    echo "  🔴 MIGRATION DESTRUCTIVE (méthode up)"
                    echo "  → Validation manuelle requise avant application"
                    NEW_DESTRUCTIVE_FOUND=true
                else
                    echo "  ✅ Migration sûre (destructive seulement dans down())"
                fi
            else
                echo "  ✅ Migration sûre (ADD/CREATE uniquement)"
            fi
        fi
        echo ""
    fi
done

if [ "$NEW_DESTRUCTIVE_FOUND" = true ]; then
    echo "⚠️  ATTENTION : Nouvelles migrations destructives détectées"
    echo "  → Validation manuelle requise avant application"
    exit 1
else
    echo "✅ Toutes les nouvelles migrations sont sûres"
    exit 0
fi

