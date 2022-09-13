# Sprinter Wi-Fi

Проект ISA-8 платы для подключения Wi-Fi модуля ESP8266 к персональному любительскому компьютеру Sprinter.

Программное обеспечение, в настоящее время, в разработке.

![image](Export/sprinter-esp.jpg)

[Принципиальная схема](Export/Schematic_Sprinter-ESP_v1.0.2.pdf)

[Монтажная схема](Export/PCB_Sprinter-ESP-v1.0.2.pdf)

[Спринтер в Телеграм](https://t.me/zx_sprinter)

[Спринтер в Web](https://www.sprinter.ru/)

## Изменения
V *1.0.3* Устранена ошибка с перепутанными сигналами RTS и CTS. В [документе](Docs/rts-cts-fix.pdf) описано, как это исправить на старых версиях платы.

Часто, модули с Ali идут без прошивки ESP-AT. В таком виде карта Sprinter Wi-Fi работать не будет, модуль ESP нужно прошить. Инструкция в [документе](Docs/ESP-module-flashing.pdf).