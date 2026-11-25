# Tetris FPGA (Zybo Z7-10)

Final Project Perancangan Sistem Digital (PSD): implementasi game Tetris pakai VHDL di board Digilent Zybo Z7-10 dengan output HDMI 640x480 @ 60Hz.

## Hardware & Software

- Board: Digilent Zybo Z7-10 (`xc7z010clg400-1`)
- Tool: Xilinx / AMD Vivado
- Bahasa: VHDL
- I/O yang dipakai: HDMI TX, 4 Push Button (`BTN0`-`BTN3`), Slide Switch (`SW0`-`SW3`)

## Struktur Folder

```text
.
├── constraints/
│   └── Zybo-Z7-Master.xdc
├── src/
│   ├── clk_gen.vhd
│   ├── vga_timing.vhd
│   ├── tmds_encoder.vhd
│   ├── hdmi_tx.vhd
│   ├── display_test_top.vhd
│   ├── btn_controller.vhd
│   ├── tetris_pkg.vhd
│   ├── tetromino_gen.vhd
│   ├── collision_check.vhd
│   └── grid_manager.vhd
└── sim/
    ├── clk_gen_tb.vhd
    ├── vga_timing_tb.vhd
    ├── tmds_encoder_tb.vhd
    ├── hdmi_tx_tb.vhd
    ├── btn_controller_tb.vhd
    ├── tetromino_gen_tb.vhd
    ├── collision_check_tb.vhd
    └── grid_manager_tb.vhd
```

## Modul yang Sudah Dibuat

**Display & HDMI**
- `clk_gen.vhd` : MMCM clock generator (25.18 MHz pixel clock & 125.89 MHz TMDS clock) + reset sync
- `vga_timing.vhd` : timing generator 640x480 @ 60Hz
- `tmds_encoder.vhd` : encoder DVI 8b/10b TMDS
- `hdmi_tx.vhd` : serializer HDMI (`OSERDESE2` + `OBUFDS`)
- `display_test_top.vhd` : top-level test pattern grid Tetris via HDMI

**Input & Core Logic**
- `btn_controller.vhd` : synchronizer, debouncer, dan edge detector untuk 4 tombol
- `tetris_pkg.vhd` : konstanta, tipe grid 10x20, dan bentuk 7 tetromino
- `tetromino_gen.vhd` : random piece generator pakai 16-bit LFSR
- `collision_check.vhd` : cek tabrakan dengan dinding, lantai, dan blok di grid
- `grid_manager.vhd` : lock bidak ke grid 10x20 dan line clearing

## Cara Pakai di Vivado

1. Buat RTL Project baru di Vivado untuk part `xc7z010clg400-1` (Zybo Z7-10).
2. Add semua file di `src/` sebagai Design Sources.
3. Add `constraints/Zybo-Z7-Master.xdc` sebagai Constraints.
4. Add file di `sim/` sebagai Simulation Sources kalau mau jalanin behavioral simulation.
5. Untuk tes di board, tinggal Run Synthesis, Implementation, lalu Generate Bitstream.

## Author

Chrysilla Azalea Pangkey
