# Grenoble Roller – Events Platform

### Short Description
Community platform to organize and discover rollerblading outings in Grenoble, managed by verified organizers.

## Overview
A web app centralizing roller events in Grenoble. Members browse events; verified organizers create and publish outings.

## Goals
- Bring the Grenoble roller community together
- Make event creation and discovery simple
- Highlight predefined routes (maps)

## Roles
- **User**: browses events, suggests outing ideas
- **Verified Organizer**: creates and publishes events, manages their details
- **Admin**: verifies organizers, moderates content

## Key Features
- Upcoming events list (vertical cards with cover photo)
- Event details: date/time, duration, location, route, description
- Member-submitted outing ideas (with validation/moderation)
- Map with predefined routes (simple display)
- Small association goodies shop
- Authentication; only verified organizers can create events

## Constraints & Decisions
- No seat limits on events
- Cover photos required on events
- Profiles stay private; users can only edit their own profile

## 🎯 Méthodologie Shape Up

**Appetite fixe (6 semaines), scope flexible** - Si pas fini → réduire scope, pas étendre deadline.

### 4 Phases Shape Up
1. **SHAPING** (Semaine -2 à 0) : Définir les limites
2. **BETTING TABLE** (Semaine 0) : Priorisation brutale  
3. **BUILDING** (Semaine 1-6) : Livrer feature shippable
4. **COOLDOWN** (Semaine 7-8) : Repos obligatoire

### Rabbit Holes Évités
- ❌ Microservices → Monolithe Rails d'abord
- ❌ Kubernetes → Docker Compose simple
- ❌ Internationalisation → MVP français uniquement
- ❌ API publique → API interne uniquement

## Future Enhancements (Backlog)
- Online payments for membership, goodies, paid events
- Categories/tags, filters, search
- Email or push notifications
- More advanced interactive maps (GPX tracks, stats)
