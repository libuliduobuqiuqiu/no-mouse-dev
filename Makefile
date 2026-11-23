PROJECT_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PYTHON ?= python3
# 实际生效的配置：可在这里修改，也可通过 make 参数覆盖。
MD_PREVIEW_CONFIG ?= $(PROJECT_ROOT)configs/md-preview.json
# SERVICE 留空：所有操作针对全部服务。
# SERVICE=名称：指定单个服务；SERVICE=all：显式选择全部。
SERVICE ?=
MD_PREVIEW = $(PYTHON) "$(PROJECT_ROOT)tools/md-preview/md-preview" --config "$(MD_PREVIEW_CONFIG)" $(if $(filter all,$(SERVICE)),--all,$(if $(SERVICE),--service "$(SERVICE)"))

.DEFAULT_GOAL := help
.PHONY: help update_lazyvim md-preview-config md-preview-list md-preview md-preview-bg md-preview-stop md-preview-status md-preview-logs

help:
	@printf '%s\n' \
	  '用法：make <目标> [SERVICE=名称或all] [MD_PREVIEW_CONFIG=/path/to/config.json]' \
	  '' \
	  '  help                查看帮助（默认目标）' \
	  '  md-preview-config   从样例创建实际配置（已有文件不覆盖）' \
	  '  md-preview-list     列出服务及目录、配置地址' \
	  '  md-preview          前台启动全部服务，可用 SERVICE=名称 选择' \
	  '  md-preview-bg       后台启动全部服务，可用 SERVICE=名称 选择' \
	  '  md-preview-stop     停止全部服务，可用 SERVICE=名称 选择' \
	  '  md-preview-status   查看全部状态（任一未运行时返回非零退出码）' \
	  '  md-preview-logs     查看全部后台日志，可用 SERVICE=名称 选择' \
	  '  update_lazyvim      复制本机 LazyVim 配置到项目' \
	  '' \
	  '生效配置：$(MD_PREVIEW_CONFIG)'

md-preview-config:
	@if [ -f "$(MD_PREVIEW_CONFIG)" ]; then \
	  printf '配置已存在，保留：%s\n' "$(MD_PREVIEW_CONFIG)"; \
	else \
	  mkdir -p "$$(dirname "$(MD_PREVIEW_CONFIG)")" && \
	  $(PYTHON) -c 'import pathlib, sys; pathlib.Path(sys.argv[2]).open("xb").write(pathlib.Path(sys.argv[1]).read_bytes())' "$(PROJECT_ROOT)configs/md-preview.example.json" "$(MD_PREVIEW_CONFIG)" && \
	  printf '已创建配置：%s\n' "$(MD_PREVIEW_CONFIG)"; \
	fi

update_lazyvim:
	cp -r /root/.config/nvim/lua/config lazyvim-lua/.
	cp -r /root/.config/nvim/lua/plugins lazyvim-lua/.

md-preview:
	$(MD_PREVIEW) start

md-preview-list:
	$(MD_PREVIEW) list

md-preview-bg:
	$(MD_PREVIEW) start --background

md-preview-stop:
	$(MD_PREVIEW) stop

md-preview-status:
	$(MD_PREVIEW) status

md-preview-logs:
	$(MD_PREVIEW) logs
