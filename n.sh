#!/bin/bash

# Data files
EVENTS_FILE="events.txt"
BOOKINGS_FILE="bookings.txt"

# Ensure required files exist
if [[ ! -f "$EVENTS_FILE" ]]; then
    touch "$EVENTS_FILE"
    echo "Sample Event | 2024-12-01 | Sample Venue | 50" >> "$EVENTS_FILE"
fi
if [[ ! -f "$BOOKINGS_FILE" ]]; then
    touch "$BOOKINGS_FILE"
fi

# Color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validate date format (YYYY-MM-DD)
validate_date_format() {
    date_regex="^[0-9]{4}-[0-9]{2}-[0-9]{2}$"
    if [[ ! "$1" =~ $date_regex ]]; then
        echo -e "${RED}Invalid date format. Use YYYY-MM-DD.${NC}"
        return 1
    fi
    if ! date -d "$1" &>/dev/null; then
        echo -e "${RED}Invalid date. Please enter a valid date.${NC}"
        return 1
    fi
    current_date=$(date +"%Y-%m-%d")
    if [[ "$1" < "$current_date" ]]; then
        echo -e "${RED}Date cannot be in the past. Enter a future date.${NC}"
        return 1
    fi
    return 0
}

# Display all events
view_events() {
    echo -e "${BLUE}Available Events:${NC}"
    if [[ ! -s $EVENTS_FILE ]]; then
        echo -e "${RED}No events available.${NC}"
        return
    fi
    nl -w2 -s". " "$EVENTS_FILE"
}

# Admin: Add a new event
add_event() {
    read -p "Enter event name: " event_name
    while true; do
        read -p "Enter event date (YYYY-MM-DD): " event_date
        if validate_date_format "$event_date"; then
            break
        fi
    done
    read -p "Enter event venue: " event_venue
    read -p "Enter event amount: " event_amount

    # Check if the event already exists with the same date and venue
    if grep -q "$event_date | $event_venue" "$EVENTS_FILE"; then
        echo -e "${RED}An event with the same date and venue already exists.${NC}"
        return
    fi

    echo "$event_name | $event_date | $event_venue | $event_amount" >> "$EVENTS_FILE"
    echo -e "${GREEN}Event added successfully.${NC}"
}

# Admin: Update an event
update_event() {
    view_events
    read -p "Enter event ID to update: " event_id
    event_line=$(sed -n "${event_id}p" "$EVENTS_FILE")
    if [[ -z $event_line ]]; then
        echo -e "${RED}Invalid event ID.${NC}"
        return
    fi
    echo -e "${BLUE}Updating Event:${NC} $event_line"
    read -p "Enter new event name: " new_event_name
    while true; do
        read -p "Enter new event date (YYYY-MM-DD): " new_event_date
        if validate_date_format "$new_event_date"; then
            break
        fi
    done
    read -p "Enter new event venue: " new_event_venue
    read -p "Enter new event amount: " new_event_amount
    sed -i "${event_id}s/.*/$new_event_name | $new_event_date | $new_event_venue | $new_event_amount/" "$EVENTS_FILE"
    echo -e "${GREEN}Event updated successfully.${NC}"
}

# Admin: Remove an event
remove_event() {
    view_events
    read -p "Enter event ID to remove: " event_id
    if [[ -z $(sed -n "${event_id}p" "$EVENTS_FILE") ]]; then
        echo -e "${RED}Invalid event ID.${NC}"
        return
    fi
    sed -i "${event_id}d" "$EVENTS_FILE"
    echo -e "${GREEN}Event removed successfully.${NC}"
}

# Admin: View all bookings
view_all_bookings() {
    echo -e "${BLUE}All Bookings:${NC}"
    if [[ ! -s $BOOKINGS_FILE ]]; then
        echo -e "${RED}No bookings found.${NC}"
        return
    fi
    cat "$BOOKINGS_FILE"
    total_bookings=$(wc -l < "$BOOKINGS_FILE")
    echo -e "${GREEN}Total Bookings: $total_bookings.${NC}"
}

# User: Book an event
book_event() {
    view_events
    read -p "Enter event ID to book: " event_id
    event_line=$(sed -n "${event_id}p" "$EVENTS_FILE")
    if [[ -z $event_line ]]; then
        echo -e "${RED}Invalid event ID.${NC}"
        return
    fi
    event_name=$(echo "$event_line" | cut -d'|' -f1)
    event_date=$(echo "$event_line" | cut -d'|' -f2)
    event_venue=$(echo "$event_line" | cut -d'|' -f3)
    event_amount=$(echo "$event_line" | cut -d'|' -f4 | tr -d ' ')

    if grep -q "$event_date at $event_venue" "$BOOKINGS_FILE"; then
        echo -e "${RED}An event on this date and venue is already booked.${NC}"
        return
    fi

    echo "$USER booked event: $event_name on $event_date at $event_venue. Cost: $event_amount" >> "$BOOKINGS_FILE"
    echo -e "${GREEN}Event booked successfully. Cost: $event_amount.${NC}"
}

# User: Unbook an event
unbook_event() {
    echo -e "${BLUE}Your Booked Events:${NC}"
    user_bookings=$(grep "$USER booked event:" "$BOOKINGS_FILE")
    if [[ -z $user_bookings ]]; then
        echo -e "${RED}No bookings found.${NC}"
        return
    fi
    echo "$user_bookings" | nl -w2 -s". "
    read -p "Enter booking ID to cancel: " booking_id
    booking_line=$(echo "$user_bookings" | sed -n "${booking_id}p")
    if [[ -z $booking_line ]]; then
        echo -e "${RED}Invalid booking ID.${NC}"
        return
    fi
    sed -i "/$booking_line/d" "$BOOKINGS_FILE"
    echo -e "${GREEN}Booking cancelled successfully.${NC}"
}

# User: View booked events and total cost
view_user_bookings() {
    echo -e "${BLUE}Your Booked Events:${NC}"
    user_bookings=$(grep "$USER booked event:" "$BOOKINGS_FILE")
    if [[ -z $user_bookings ]]; then
        echo -e "${RED}No bookings found.${NC}"
        return
    fi
    echo "$user_bookings" | nl -w2 -s". "
    total_cost=$(echo "$user_bookings" | awk -F 'Cost: ' '{sum += $2} END {print sum}')
    echo -e "${GREEN}Total Cost of Booked Events: $total_cost.${NC}"
}

# Admin menu
admin_menu() {
    while true; do
        echo -e "${YELLOW}Admin Menu:${NC}"
        echo "1. Add Event"
        echo "2. Update Event"
        echo "3. Remove Event"
        echo "4. View Events"
        echo "5. View All Bookings"
        echo "6. Logout"
        read -p "Choose an option: " admin_choice
        case $admin_choice in
            1) add_event ;;
            2) update_event ;;
            3) remove_event ;;
            4) view_events ;;
            5) view_all_bookings ;;
            6) break ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
}

# User menu
user_menu() {
    while true; do
        echo -e "${YELLOW}User Menu:${NC}"
        echo "1. View Events"
        echo "2. Book Event"
        echo "3. Unbook Event"
        echo "4. View Booked Events"
        echo "5. Logout"
        read -p "Choose an option: " user_choice
        case $user_choice in
            1) view_events ;;
            2) book_event ;;
            3) unbook_event ;;
            4) view_user_bookings ;;
            5) break ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
}

# Main menu
while true; do
    echo -e "${YELLOW}Welcome to the Event Management System${NC}"
    echo "1. Admin Login"
    echo "2. User Login"
    echo "3. Exit"
    read -p "Choose an option: " main_choice
    case $main_choice in
        1) admin_menu ;;
        2) user_menu ;;
        3) exit ;;
        *) echo -e "${RED}Invalid option.${NC}" ;;
    esac
done
