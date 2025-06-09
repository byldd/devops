if command -v docker compose; then
    exec su - ubuntu
else 
    echo "Nah man"    
fi