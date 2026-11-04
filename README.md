# rana-doro

Un timer cozy que no te apura. Pomodoro suave 25/5, una sola pantalla, sin cuentas, sin nube, sin analítica y sin anuncios.

- **Stack:** Flutter 3.47.1 / Dart 3.13.1
- **Plataforma inicial:** Android (Play Store + F-Droid)
- **Paquete:** `com.josefrancisco.ranadoro`
- **Nombre visible:** `rana-doro`
- **Tipografías:** Caveat (etiquetas) + Inter (tiempo y cuerpo), empaquetadas localmente con licencia OFL
- **Estado:** S1–S4 completos. S5 verificado en Android 11; falta Android 13/14, TalkBack y metadata de tienda.

## Qué hace

- Enfoque de 25:00 y descanso de 05:00.
- Tocar el temporizador inicia o pausa.
- "Reiniciar" aparece solo en pausa.
- Al terminar una fase, la siguiente queda lista y no arranca sola.
- Persistencia local con reloj de pared: sobrevive a cerrar la app o bloquear el teléfono.
- Rana focus mientras corre y rana por defecto en reposo, pausa y terminado.
- Notificación local silenciosa al terminar, con permiso Android 13+ y alarma exacta cuando el sistema lo permite.
- Tema claro/oscuro del sistema.
- Icono adaptativo y splash con la rana.
- Accesibilidad: lector de pantalla, texto al 200 %, movimiento reducido.

## Comandos

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

## Estructura

```
lib/
  app.dart
  main.dart
  core/                 # marca, reloj, tokens, tema
  features/timer/
    application/        # TimerController
    data/               # persistencia local
    domain/             # fases, estados, formato
    presentation/       # pantalla única
  services/             # notificaciones locales
assets/
  fonts/                # Caveat + Inter (OFL)
  images/               # rana idle + rana focus
test/                   # unit, widget y golden
```

## Privacidad

## Privacidad

No se recogen datos. No hay cuentas, nube ni analítica. El manifest de release no incluye `INTERNET`. Todo el estado vive en `SharedPreferences` del dispositivo. Ver `PRIVACY.md`.

## Siguientes pasos

1. Probar en Android 13/14: permiso concedido/denegado, alarma exacta, reboot, TalkBack y batería restringida.
2. Preparar metadata de F-Droid y capturas de tienda.
3. Beta cerrada con 12 testers y lanzamiento.
4. Firmar el build de release y publicar en Play + F-Droid.
