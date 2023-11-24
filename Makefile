build:
	@pdc source/ build

run:
	@open build.pdx

build-run:
	@make build
	@make run