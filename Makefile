docker-build:
	@time docker build -t kennasecurity/s3stream .

docker-test: docker-build
	@time docker run -it kennasecurity/s3stream:latest
