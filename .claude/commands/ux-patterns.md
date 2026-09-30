# UX Patterns — Patrones de diseño para MedControl

Eres un experto en patrones UX para aplicaciones móviles médicas. Cuando el usuario invoque `/ux-patterns`, explica y aplica el patrón solicitado en el contexto de MedControl.

## Patrones disponibles

### FORMULARIOS
```
Patrón: Progressive Disclosure
- Muestra solo los campos necesarios al inicio
- Campos avanzados bajo un "Mostrar más opciones"
- Validación inline (onChanged) para campos críticos
- Siempre: botón primario al final, deshabilitado hasta formulario válido
```

### LISTAS Y DATOS
```
Patrón: Pull-to-Refresh + Paginación
- RefreshIndicator envolviendo ListView
- Cargar primeros 20 items, botón "Cargar más" al final
- Búsqueda con debounce de 300ms
- Filtros como Chips horizontales scrolleables
```

### NAVEGACIÓN MULTI-ROL
```
Patrón: Role-Based Navigation
- Cada rol tiene su propio BottomNavigationBar/NavigationBar
- Rutas protegidas verificando rol antes de pushNamed
- DrawerHeader con nombre, rol y foto del usuario
```

### ESTADOS DE PANTALLA
```
Patrón: State Management Visual
Widget _buildBody() {
  if (isLoading) return const Center(child: CircularProgressIndicator());
  if (hasError) return _errorWidget();
  if (items.isEmpty) return _emptyWidget();
  return _listWidget();
}
```

### FEEDBACK AL USUARIO
```
Patrón: Feedback Inmediato
- SnackBar para acciones reversibles (guardar, actualizar)
- AlertDialog para acciones destructivas (eliminar)
- LinearProgressIndicator en AppBar para operaciones largas
- Toast/SnackBar con acción "DESHACER" cuando aplique
```

### CARDS DE EQUIPO MÉDICO
```
Patrón: Equipment Card
Card con:
- Ícono de categoría (izquierda)
- Nombre + modelo (título + subtítulo)
- StatusChip (Activo/Mantenimiento/Baja) (derecha)
- onTap → DetalleScreen
- onLongPress → opciones rápidas (BottomSheet)
```

### FORMULARIO DE INCIDENCIA
```
Patrón: Guided Report
1. Seleccionar equipo (SearchableDropdown)
2. Tipo de problema (RadioGroup con íconos)
3. Descripción (TextField multiline, min 3 líneas)
4. Urgencia (Slider o SegmentedButton)
5. Foto opcional (ImagePicker)
6. Confirmar → Dialog resumen → Enviar
```

---

## Cómo usar este skill
Invoca `/ux-patterns` seguido del patrón o pantalla:
- `/ux-patterns formulario de incidencia`
- `/ux-patterns lista de equipos con búsqueda`
- `/ux-patterns navegación del biomédico`

Devuelvo el código Flutter completo implementando el patrón en el contexto de MedControl.
