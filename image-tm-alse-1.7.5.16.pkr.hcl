#Образ на основе ALSE 1.7.5 UU1 для инфраструктурных компонентов Термидеска

packer {
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}
source "qemu" "gi-tm-alse-1-7-5-16" {
  # По умолчанию, 'go-getter' должен использовать для подключения к S3 профиль
  # '[default]'.
  # Однако это не работает, не работают и  переменные AWS_ACCESS_KEY_ID и
  # AWS_SECRET_ACCESS_KEY
  # (см. https://stackoverflow.com/questions/39051477/the-aws-access-key-id-does
  # -not-exist-in-our-records/71636705?__cf_chl_tk=IWCMlgspF5uHrlPo3XI7D4ry1_icfREIyu1owflFFsw-1718032758-0.0.1.1-4585)
  # Из-за этого ключи прописаны в URL, по-хорошему надо поменять.
  iso_url          = "s3::http://10.177.130.41:9000/termidesk-automation/alse-installation-1.7.5.16-06.02.24_14.21.iso?aws_access_key_id=xxx&aws_access_key_secret=xxx"
  iso_checksum     = "none" #Надо поменять на нормальную чек-сумму
  output_directory = "packer-alse-1-7-5-16"
  disk_size        = "12000M"
  disk_interface   = "virtio"
  format           = "qcow2"
  machine_type     = "q35"
  memory           = "8096"
  accelerator      = "kvm"
  # net_device       = "e1000"
  cpu_model      = "host"
  http_directory = "http"

  # https://wiki.archlinux.org/title/QEMU#Graphic_card
  vga = "qxl"

  vm_name = "gi-tm-alse-1-7-5-16"

  # Коммуникатор 'SSH' не работает нормально, либо нужна хитрая настройка.
  # Так как настройку готового образа будут выполнять другие инструменты,
  # проще всего отключить коммуникатор, он нам не нужен.
  communicator = "none"

  # Прописываем последовательность клавиш, которые Packer прожмёт после запуска ВМ
  boot_wait = "2s"
  boot_command = [ #За основу взяты стандартные boot-параметры установщика ALSE
    "<enter><wait>",
    "<f2><esc><wait>",
    # Я не нашёл способа, как в ALSE можно выделить всю строку с boot-параметрами и
    # удалить её. Судя по всему, в плагине QEMU для Packer также нет подходящей
    # комбинации, и мы не можем указать число, сколько раз надо нажать
    # какую-то клавишу. Поэтому я прописываю 140 раз клавишу 'backspace'.
    "<tab>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "initrd=/install.amd/gtk/initrd.gz ",
    "modprobe.blacklist=evbug ",
    # См. про этот параметр на https://wiki.astralinux.ru/pages/viewpage
    # .action?pageId=263031254
    # "astra_install=1 ",
    "astra-license/license=true ",
    "priority=critical ",
    "auto=true ",
    # Этот параметр есть в примере ALSE
    "vga=788 ",
    "hostname=gi-tm-alse-1-7-5-16 ",
    # debian-installer/locale=en_US console-keymaps-at/keymap=ru
    # При получении preseed-файла из сети, сетевые настройки указываются в
    # boot-параметрах (https://wiki.debian
    # .org/DebianInstaller/Preseed#Loading_the_preseeding_file_from_a_webserver)
    "interface=auto ",
    "netcfg/dhcp_timeout=60 ",
    # Переносим некоторые вопросы, на которые нельзя ответить автоматически в
    # начале установки, в её конец
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed-tm-alse-1.7.5.16.cfg<wait5>",
    "<enter><wait>"
  ]
  # Не используем 'shutdown_command', потому что у нас не работает 'communicator'.
  # После установки образа на ВМ, она будет запущена,
  # чтобы вы могли убедиться, что установка прошла успешно
  # shutdown_command = "echo 'packer' | sudo -S shutdown -P now"

  # 75 минут достаточно для установки на любой системе и логина в систему.
  # Если система не установилась за это время, вследствие чего
  # Packer упал в ошибку, значит, возникли какие-то проблемы.
  shutdown_timeout = "75m"
}

build {
  sources = ["source.qemu.gi-tm-alse-1-7-5-16"]
}

