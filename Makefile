# os deps: node npm git jq docker
# npm deps: eslint eslint-plugin-unicorn stylelint uglify-js grunt npm-check-updates yarn

X86 := $(shell uname -m | grep 86)
ifeq ($(X86),)
	IMAGE=avnerus/armhf-droppy
else
	IMAGE=avnerus/droppy
endif

JQUERY_FLAGS=-ajax,-css,-deprecated,-effects,-event/alias,-event/focusin,-event/trigger,-wrap,-core/ready,-deferred,-exports/amd,-sizzle,-offset,-dimensions,-serialize,-queue,-callbacks,-event/support,-event/ajax,-attributes/prop,-attributes/val,-attributes/attr,-attributes/support,-manipulation/setGlobalEval,-manipulation/support,-manipulation/var/rcheckableType,-manipulation/var/rscriptType

deps:
	yarn global add eslint@latest eslint-plugin-unicorn@latest stylelint@latest uglify-js@latest grunt@latest npm-check-updates@latest

lint:
	eslint --color --ignore-pattern *.min.js --plugin unicorn --rule 'unicorn/catch-error-name: [2, {name: err}]' --rule 'unicorn/throw-new-error: 2' server client *.js
	stylelint client/*.css

build:
	touch client/client.js
	node droppy.js build

publish:
	if git ls-remote --exit-code origin &>/dev/null; then git push -u -f --tags origin master; fi
	if git ls-remote --exit-code gogs &>/dev/null; then git push -u -f --tags gogs master; fi
	npm publish

docker:
	@echo Preparing docker image $(IMAGE)...
	docker pull resin/odroid-ux3-alpine-node:4-slim
	docker rm -f "$$(docker ps -a -f='ancestor=$(IMAGE)' -q)" 2>/dev/null || true
	docker rmi "$$(docker images -qa $(IMAGE))" 2>/dev/null || true
	docker build --no-cache=true -t $(IMAGE) .
	docker tag "$$(docker images -qa $(IMAGE):latest)" $(IMAGE):"$$(cat package.json | jq -r .version)"

docker-push:
	docker push $(IMAGE):"$$(cat package.json | jq -r .version)"
	docker push $(IMAGE):latest

update:
	ncu --packageFile package.json -ua
	rm -rf node_modules
	yarn
	touch client/client.js

deploy:
	git commit --allow-empty --allow-empty-message -m ""
	if git ls-remote --exit-code demo &>/dev/null; then git push -f demo master; fi
	if git ls-remote --exit-code droppy &>/dev/null; then git push -f droppy master; fi
	git reset --hard HEAD~1

jquery:
	git clone --depth 1 https://github.com/silverwind/jquery /tmp/jquery
	cd /tmp/jquery; npm run build; grunt custom:$(JQUERY_FLAGS); grunt remove_map_comment
	cat /tmp/jquery/dist/jquery.min.js | perl -pe 's|"3\..+?"|"3"|' > $(CURDIR)/client/jquery-custom.min.js
	rm -rf /tmp/jquery

npm-patch:
	npm version patch

npm-minor:
	npm version minor

npm-major:
	npm version major

patch: lint build npm-patch deploy publish docker docker-push
minor: lint build npm-minor deploy publish docker docker-push
major: lint build npm-major deploy publish docker docker-push

.PHONY: deps lint publish docker update deploy jquery npm-patch npm-minor npm-major patch minor major
