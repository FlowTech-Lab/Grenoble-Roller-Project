#!/bin/bash
###############################################################################
# Module: database/migrations.sh
# Description: Gestion des migrations Rails (vérification, application, analyse)
# Dependencies: 
#   - core/logging.sh
#   - docker/containers.sh (container_is_running)
#   - Variables: CONTAINER_NAME, ENV, REPO_DIR
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

# Vérifier que toutes les migrations locales sont présentes dans le conteneur
verify_migrations_synced() {
    local container=$1
    local expected_count=$2
    local local_list=$3
    
    # Lister migrations dans le conteneur
    local container_list=$($DOCKER_CMD exec "$container" find /rails/db/migrate -name "*.rb" -type f -exec basename {} \; 2>/dev/null | sort || echo "")
    
    if [ -z "$container_list" ]; then
        log_error "❌ Impossible de lister les migrations dans le conteneur"
        return 1
    fi
    
    local container_count=$(echo "$container_list" | wc -l | tr -d ' ')
    
    # Vérifier le nombre
    if [ "$container_count" -ne "$expected_count" ]; then
        log_warning "⚠️  Nombre de migrations différent : attendu=${expected_count}, conteneur=${container_count}"
        return 1
    fi
    
    # Vérifier que toutes les migrations locales sont dans le conteneur
    local missing=$(comm -23 <(echo "$local_list") <(echo "$container_list") || echo "")
    
    if [ -n "$missing" ]; then
        log_error "❌ Migrations manquantes dans le conteneur :"
        echo "$missing" | while read -r migration; do
            log_error "  🔴 $migration"
        done
        return 1
    fi
    
    log_success "✅ Migrations synchronisées (${expected_count} fichiers)"
    return 0
}

# Analyser les migrations en attente pour détecter les destructives
# IMPORTANT : Vérifie si les migrations destructives sont déjà appliquées (up) ou nouvelles (down)
analyze_destructive_migrations() {
    local container=$1
    local migration_status=$($DOCKER_CMD exec "$container" bin/rails db:migrate:status 2>&1 | grep -v "Generating image" | grep -v "Please add" || echo "")
    local pending_migrations=$(echo "$migration_status" | grep "^\s*down" || echo "")
    
    if [ -z "$pending_migrations" ]; then
        return 0  # Pas de migrations en attente
    fi
    
    # Patterns destructifs dans la méthode up() (ceux-ci sont dangereux)
    local destructive_patterns_up="drop_table|remove_column|remove_index|remove_foreign_key|remove_reference|remove_timestamps|remove_belongs_to|change_column_null.*false|execute.*DELETE|execute.*TRUNCATE|execute.*DROP"
    
    # Patterns destructifs dans les noms de migrations (pour détection rapide)
    local destructive_names="Remove|Drop|Destroy|Delete|Truncate|Clear|Rename.*Column|Change.*Column.*Type"
    
    local new_destructive_found=false
    local destructive_list=""
    
    # Analyser chaque migration en attente
    while IFS= read -r migration_line; do
        # Extraire l'ID de migration depuis la ligne "down  20251124020634  Add confirmable to users"
        local mig_id=$(echo "$migration_line" | awk '{print $2}' | cut -d'_' -f1)
        local mig_name=$(echo "$migration_line" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/ $//')
        
        # Chercher le fichier de migration correspondant
        local mig_file=$(find "${REPO_DIR:-.}/db/migrate" -name "${mig_id}_*.rb" -type f 2>/dev/null | head -1)
        
        if [ -n "$mig_file" ] && [ -f "$mig_file" ]; then
            # Vérifier si la méthode up() contient des opérations destructives
            if grep -qiE "$destructive_patterns_up" "$mig_file"; then
                # Vérifier si c'est dans la méthode up() (dangereux) ou seulement dans down() (OK)
                if grep -A 30 "^  def up" "$mig_file" | grep -qiE "$destructive_patterns_up"; then
                    # Migration destructive dans up() - NOUVELLE et DANGEREUSE
                    destructive_list="${destructive_list}${mig_id} ${mig_name}\n"
                    new_destructive_found=true
                fi
                # Si destructive seulement dans down(), c'est OK (on n'applique jamais down() automatiquement)
            fi
        fi
    done <<< "$pending_migrations"
    
    if [ "$new_destructive_found" = true ]; then
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "⚠️  ⚠️  ⚠️  NOUVELLES MIGRATIONS DESTRUCTIVES DÉTECTÉES ⚠️  ⚠️  ⚠️"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "Les migrations suivantes peuvent supprimer ou modifier définitivement des données :"
        echo -e "$destructive_list" | while read -r mig_id mig_name; do
            [ -n "$mig_id" ] && log_error "  🔴 ${mig_id} - ${mig_name}"
        done
        
        if [ "${ENV:-}" = "production" ]; then
            # Vérifier si --force est activé
            if [ "${FORCE_REDEPLOY:-false}" = "true" ]; then
                log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                log_warning "⚠️  Mode --force activé, exécution des migrations destructives"
                log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                return 0  # Autoriser l'exécution
            fi
            
            log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log_error "🔴 PRODUCTION : Approbation manuelle requise"
            log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log_warning ""
            log_warning "Voulez-vous continuer malgré les migrations destructives ?"
            log_warning ""
            log_warning "⚠️  ATTENTION : Ces migrations peuvent modifier ou supprimer des données !"
            log_warning ""
            log_warning "💡 Astuce : Utilisez --force pour forcer l'exécution"
            log_warning ""
            
            # Vérifier si on est en mode interactif
            if [ ! -t 0 ]; then
                log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                log_error "❌ Mode non-interactif détecté"
                log_error "Utilisez --force pour forcer l'exécution"
                log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                return 1
            fi
            
            # Demander confirmation interactive
            while true; do
                read -p "Continuer quand même ? (oui/non) : " response
                case "$response" in
                    [Oo]ui|[Oo]|yes|[Yy])
                        log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        log_warning "⚠️  Exécution des migrations destructives approuvée manuellement"
                        log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        return 0  # Autoriser l'exécution
                        ;;
                    [Nn]on|[Nn]|no|[Nn])
                        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        log_error "❌ Exécution annulée par l'utilisateur"
                        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        return 1  # Refuser l'exécution
                        ;;
                    *)
                        log_warning "Réponse invalide. Veuillez répondre 'oui' ou 'non'."
                        ;;
                esac
            done
        else
            log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log_warning "⚠️  STAGING : Migration destructive détectée"
            log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log_warning "Exécution automatique en staging (review recommandée)"
            log_warning "Si vous voulez ARRÊTER, appuyez sur Ctrl+C maintenant"
            for i in {10..1}; do
                echo -ne "\rContinuation dans ${i}s...   "
                sleep 1
            done
            echo ""
            log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log_info "Continuation de l'exécution..."
        fi
    fi
    
    return 0
}

# Calculer timeout adaptatif pour migrations
calculate_migration_timeout() {
    local pending_count=$1
    local base_timeout=${MIGRATION_BASE_TIMEOUT:-60}
    local per_migration=${MIGRATION_PER_MIGRATION:-30}
    local max_timeout=${MIGRATION_MAX_TIMEOUT:-900}
    
    # Multiplicateur selon l'environnement
    local env_multiplier=1
    if [ "${ENV:-}" = "production" ]; then
        env_multiplier=2
        max_timeout=${MIGRATION_MAX_TIMEOUT_PRODUCTION:-1800}
    fi
    
    local calculated=$((base_timeout + (pending_count * per_migration * env_multiplier)))
    echo $((calculated > max_timeout ? max_timeout : calculated))
}

# Appliquer les migrations
apply_migrations() {
    local container=$1
    local migration_timeout=${2:-900}
    
    log "🗄️ Exécution des migrations (timeout: ${migration_timeout}s)..."
    local migration_start_time=$(date +%s)
    
    # Détecter la version de timeout
    local timeout_cmd=""
    local timeout_exit_code=124
    
    if command -v timeout > /dev/null 2>&1; then
        if timeout --version 2>&1 | grep -q "GNU\|coreutils"; then
            timeout_cmd="timeout"
            timeout_exit_code=124
        elif timeout 1 sleep 0 2>&1 | grep -q "usage"; then
            timeout_cmd="timeout"
            timeout_exit_code=143
        elif command -v gtimeout > /dev/null 2>&1; then
            timeout_cmd="gtimeout"
            timeout_exit_code=124
        fi
    fi
    
    # Exécuter migrations principales (PostgreSQL)
    # ⚠️  IMPORTANT : db:migrate ne fait QUE appliquer les migrations en attente
    #    - Ne supprime AUCUNE donnée existante
    #    - Ne touche QUE la base PostgreSQL principale
    #    - La queue SQLite reste complètement intacte
    log_info "   ℹ️  db:migrate est SÉCURISÉ : applique uniquement les migrations en attente"
    log_info "   ℹ️  Aucune donnée existante ne sera supprimée"
    local migration_output
    local migration_exit_code
    
    if [ -n "$timeout_cmd" ]; then
        migration_output=$($timeout_cmd ${migration_timeout} $DOCKER_CMD exec "$container" bin/rails db:migrate 2>&1)
        migration_exit_code=$?
    else
        log_warning "⚠️  Commande 'timeout' non disponible, exécution sans timeout"
        migration_output=$($DOCKER_CMD exec "$container" bin/rails db:migrate 2>&1)
        migration_exit_code=$?
    fi
    
    local migration_end_time=$(date +%s)
    local migration_duration=$((migration_end_time - migration_start_time))
    export MIGRATION_DURATION=$migration_duration
    
    echo "$migration_output" | tee -a "${LOG_FILE:-/dev/stdout}"
    
    # Vérifier timeout
    if [ $migration_exit_code -eq 124 ] || [ $migration_exit_code -eq 143 ] || [ $migration_exit_code -eq 137 ]; then
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "⏱️  TIMEOUT : Migration a dépassé ${migration_timeout}s"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        return 1
    fi
    
    if [ $migration_exit_code -ne 0 ]; then
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "❌ Échec des migrations (durée: ${migration_duration}s)"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        return 1
    fi
    
    log_success "✅ Migrations principales exécutées avec succès (durée: ${migration_duration}s)"
    
    # Vérification post-migration principales
    local post_status=$($DOCKER_CMD exec "$container" bin/rails db:migrate:status 2>&1)
    local post_pending=$(echo "$post_status" | awk '/^\s*down/ {count++} END {print count+0}' 2>/dev/null || echo "0")
    
    if [ "$post_pending" -gt 0 ]; then
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "⚠️  ANOMALIE : $post_pending migration(s) encore en attente après db:migrate"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        return 1
    fi
    
    # Appliquer les migrations de la queue SQLite (Solid Queue)
    # ⚠️  IMPORTANT : db:migrate:queue est complètement SÉPARÉ de PostgreSQL
    #    - Ne touche QUE le fichier SQLite (storage/solid_queue.sqlite3)
    #    - Ne touche PAS la base PostgreSQL
    #    - Les jobs en queue restent intacts
    log "🗄️ Exécution des migrations de la queue SQLite (Solid Queue)..."
    log_info "   ℹ️  db:migrate:queue est SÉPARÉ : ne touche QUE SQLite, pas PostgreSQL"
    log_info "   ℹ️  Les jobs en queue restent intacts"
    local queue_migration_start_time=$(date +%s)
    
    # S'assurer que le répertoire storage existe
    $DOCKER_CMD exec "$container" mkdir -p /rails/storage 2>/dev/null || true
    
    # Exécuter les migrations de la queue
    local queue_migration_output
    local queue_migration_exit_code
    
    if [ -n "$timeout_cmd" ]; then
        queue_migration_output=$($timeout_cmd 300 $DOCKER_CMD exec "$container" bin/rails db:migrate:queue 2>&1)
        queue_migration_exit_code=$?
    else
        queue_migration_output=$($DOCKER_CMD exec "$container" bin/rails db:migrate:queue 2>&1)
        queue_migration_exit_code=$?
    fi
    
    local queue_migration_end_time=$(date +%s)
    local queue_migration_duration=$((queue_migration_end_time - queue_migration_start_time))
    
    echo "$queue_migration_output" | tee -a "${LOG_FILE:-/dev/stdout}"
    
    if [ $queue_migration_exit_code -eq 0 ]; then
        log_success "✅ Migrations de la queue SQLite exécutées avec succès (durée: ${queue_migration_duration}s)"
    else
        # Ne pas faire échouer le déploiement si la queue n'existe pas encore (première installation)
        if echo "$queue_migration_output" | grep -qiE "database.*does not exist|no such file|queue.*not.*configured"; then
            log_warning "⚠️  Base de données queue SQLite non configurée (normal pour première installation)"
            log_info "💡 La queue SQLite sera créée automatiquement au premier usage"
        else
            log_warning "⚠️  Échec des migrations de la queue SQLite (non bloquant)"
            log_warning "   Sortie: ${queue_migration_output}"
        fi
    fi
    
    log_success "✅ Toutes les migrations ont été appliquées correctement"
    return 0
}

