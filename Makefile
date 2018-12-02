.DEFAULT_GOAL := ignition

units = $(shell ls systemd/*)

define generate_unit_description
	$(eval BASENAME := $(shell basename $(1)))
	sed -e 's/^/        /' \
            -e '1s/^/      contents: |\n/' \
            -e '1s/^/      enabled: true\n/' \
            -e '1s/^/    - name: $(BASENAME)\n/' \
            -e '$$a\\n' $(1) >> output/systemd.yaml
endef

clean:
	rm -f output/*

output/systemd.yaml: FORCE
	rm -f output/systemd.yaml
	@$(foreach unit,$(units),$(call generate_unit_description,$(unit)))
	sed -e '1s/^/  units:\n/' \
            -e '1s/^/systemd:\n/' -i output/systemd.yaml
	@echo "INFO: output/systemd.yaml recreated"

output/systemd.json: output/systemd.yaml
	ct -in-file output/systemd.yaml | jq -j '.' > output/systemd.json

output/main.json:
	ct -in-file main.yaml | jq -j '.' > output/main.json

output/config.json:
	ct -in-file config.yaml | jq -j '.' > output/config.json

ignition: output/main.json output/config.json output/systemd.json

FORCE: