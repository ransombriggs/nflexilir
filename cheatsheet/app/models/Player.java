package models;

import org.codehaus.jackson.annotate.JsonIgnoreProperties;
import play.db.jpa.Model;

import javax.persistence.Entity;
import javax.persistence.Table;
import java.util.Date;

@Entity
@Table(name = "players")
@JsonIgnoreProperties(ignoreUnknown = true)
public class Player extends Model {

    public String name;
    public String position;

    public Long stats;
    public Long proj;

    public Long player_id;
    public Long claimed_by;
    public Long rank;
    public Long tier;

    public Date claim_time;
}
