up:
	docker compose up --build -d

down:
	docker compose down -v

restart:
	docker restart elderly-app

logs:
	docker logs -f elderly-app

migrate:
	docker exec elderly-app php artisan migrate

seed:
	docker exec elderly-app php artisan db:seed

tinker:
	docker exec -it elderly-app php artisan tinker

artisan:
	docker exec -it elderly-app php artisan

bash:
	docker exec -it elderly-app bash

health:
	curl -fsS http://localhost:8000/healthz

