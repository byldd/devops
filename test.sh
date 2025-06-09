if command -v docker compose; then
    exec su - "$LOCAL_USER"
else 
    echo "Nah man"    
fi