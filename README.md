# Conciliador Pro - Rails Edition

Sistema de conciliación bancaria migrado de React a Ruby on Rails 7+ con Hotwire.

## Requisitos

- Ruby 3.1+
- Bundler

## Instalación

```bash
# Instalar dependencias
bundle install

# Iniciar servidor
bin/rails server
```

Visita `http://localhost:3000`

## Uso

1. **Cargar extracto bancario** (CSV, XLSX o XLS)
2. **Cargar registro de ventas** (CSV, XLSX o XLS)
3. **Iniciar conciliación** - el sistema ejecuta matching en 2 pasadas:
   - Pasada 1: Match exacto (referencia + monto + fecha)
   - Pasada 2: Match fuzzy (monto ± $1, fecha ± 3 días)
4. **Ver resultados** con estadísticas y tablas navegables
5. **Exportar** a CSV (reporte completo o por categoría)

## Estructura

```
app/
├── controllers/
│   ├── reconciliations_controller.rb  # Upload, proceso, resultados
│   └── exports_controller.rb          # Exportar CSV
├── models/
│   ├── transaction_record.rb          # PORO para transacciones
│   ├── matched_pair.rb                # PORO para matches
│   └── reconciliation_result.rb       # PORO para resultados
├── services/
│   ├── file_parsing_service.rb        # Parse CSV/XLSX/XLS
│   ├── column_detection_service.rb    # Auto-detectar columnas
│   ├── reconciliation_service.rb      # Algoritmo de conciliación
│   └── export_service.rb              # Generar CSV exportable
├── views/reconciliations/
│   └── *.html.erb                     # Vistas y partials
├── javascript/controllers/
│   ├── file_upload_controller.js      # Manejo de archivos
│   ├── drag_drop_controller.js        # Drag & drop
│   └── tabs_controller.js             # Navegación tabs
└── assets/stylesheets/
    └── application.css                # Tema glassmorphism
```

## Tecnologías

- Rails 7.1 con Hotwire (Turbo + Stimulus)
- Roo gem para parsing Excel
- CSS puro con tema glassmorphism oscuro
- Sin base de datos (usa sesiones)
