"""Initial frozen PostgreSQL/PostGIS schema."""

from alembic import op

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis")

    op.execute(
        "CREATE TABLE categories (\n\tid VARCHAR(40) NOT NULL, \n\tcode VARCHAR(40) NOT NULL, \n\tname_ru VARCHAR(100) NOT NULL, \n\tname_kk VARCHAR(100) NOT NULL, \n\tdescription VARCHAR(500) NOT NULL, \n\tbase_severity INTEGER NOT NULL, \n\ticon VARCHAR(40) NOT NULL, \n\tcolor VARCHAR(10) NOT NULL, \n\tis_active BOOLEAN NOT NULL, \n\tPRIMARY KEY (id), \n\tUNIQUE (code)\n)"
    )

    op.execute(
        "CREATE TABLE organizations (\n\tname_ru VARCHAR(200) NOT NULL, \n\tname_kk VARCHAR(200) NOT NULL, \n\tcontact_data JSON NOT NULL, \n\tservice_area JSON, \n\tid UUID NOT NULL, \n\tcreated_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tPRIMARY KEY (id)\n)"
    )

    op.execute(
        "CREATE TABLE users (\n\temail VARCHAR(254) NOT NULL, \n\tphone VARCHAR(30), \n\tpassword_hash VARCHAR(255) NOT NULL, \n\tdisplay_name VARCHAR(80) NOT NULL, \n\tpreferred_language VARCHAR(5) NOT NULL, \n\trole VARCHAR(20) NOT NULL, \n\torganization_id UUID, \n\tis_active BOOLEAN NOT NULL, \n\tupdated_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tid UUID NOT NULL, \n\tcreated_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tPRIMARY KEY (id), \n\tUNIQUE (email), \n\tFOREIGN KEY(organization_id) REFERENCES organizations (id)\n)"
    )

    op.execute(
        "CREATE TABLE audit_logs (\n\tactor_id UUID, \n\tentity_type VARCHAR(50) NOT NULL, \n\tentity_id UUID NOT NULL, \n\taction VARCHAR(80) NOT NULL, \n\told_data JSON, \n\tnew_data JSON, \n\tid UUID NOT NULL, \n\tcreated_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tPRIMARY KEY (id), \n\tFOREIGN KEY(actor_id) REFERENCES users (id)\n)"
    )

    op.execute(
        "CREATE TABLE incidents (\n\tauthor_id UUID NOT NULL, \n\tsource VARCHAR(30) NOT NULL, \n\tcategory_id VARCHAR(40) NOT NULL, \n\ttitle VARCHAR(160) NOT NULL, \n\tdescription TEXT NOT NULL, \n\tlatitude FLOAT NOT NULL, \n\tlongitude FLOAT NOT NULL, \n\tlocation geography(POINT,4326) NOT NULL, \n\taddress VARCHAR(300) NOT NULL, \n\tseverity INTEGER NOT NULL, \n\tpriority_score FLOAT NOT NULL, \n\tpriority_explanation JSON NOT NULL, \n\tai_confidence FLOAT, \n\tai_explanation TEXT, \n\tstatus VARCHAR(40) NOT NULL, \n\tis_published BOOLEAN NOT NULL, \n\tis_hidden BOOLEAN NOT NULL, \n\tconfirmation_count INTEGER NOT NULL, \n\tupdated_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tresolved_at TIMESTAMP WITH TIME ZONE, \n\tid UUID NOT NULL, \n\tcreated_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tPRIMARY KEY (id), \n\tCHECK (severity BETWEEN 1 AND 10), \n\tCHECK (latitude BETWEEN -90 AND 90), \n\tCHECK (longitude BETWEEN -180 AND 180), \n\tCHECK (confirmation_count >= 0), \n\tFOREIGN KEY(author_id) REFERENCES users (id), \n\tFOREIGN KEY(category_id) REFERENCES categories (id)\n)"
    )

    op.execute("CREATE INDEX ix_incidents_author_id ON incidents (author_id)")

    op.execute("CREATE INDEX ix_incidents_status ON incidents (status)")

    op.execute("CREATE INDEX ix_incidents_category_id ON incidents (category_id)")

    op.execute(
        "CREATE TABLE refresh_sessions (\n\tuser_id UUID NOT NULL, \n\tfamily_id UUID NOT NULL, \n\ttoken_hash VARCHAR(64) NOT NULL, \n\texpires_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\trevoked BOOLEAN NOT NULL, \n\tid UUID NOT NULL, \n\tcreated_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tPRIMARY KEY (id), \n\tFOREIGN KEY(user_id) REFERENCES users (id), \n\tUNIQUE (token_hash)\n)"
    )

    op.execute("CREATE INDEX ix_refresh_sessions_family_id ON refresh_sessions (family_id)")

    op.execute("CREATE INDEX ix_refresh_sessions_user_id ON refresh_sessions (user_id)")

    op.execute(
        "CREATE TABLE uploads (\n\towner_id UUID NOT NULL, \n\tmedia_type VARCHAR(10) NOT NULL, \n\toriginal_key VARCHAR(200) NOT NULL, \n\tredacted_key VARCHAR(200), \n\tthumbnail_key VARCHAR(200), \n\tmime_type VARCHAR(100) NOT NULL, \n\tstatus VARCHAR(20) NOT NULL, \n\ttranscript TEXT, \n\tanalysis JSON, \n\tprivacy_method VARCHAR(60), \n\tcloud_consent BOOLEAN NOT NULL, \n\tlanguage VARCHAR(5) NOT NULL, \n\tid UUID NOT NULL, \n\tcreated_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tPRIMARY KEY (id), \n\tFOREIGN KEY(owner_id) REFERENCES users (id)\n)"
    )

    op.execute(
        "CREATE TABLE comments (\n\tincident_id UUID NOT NULL, \n\tauthor_id UUID NOT NULL, \n\ttext VARCHAR(2000) NOT NULL, \n\tis_hidden BOOLEAN NOT NULL, \n\tid UUID NOT NULL, \n\tcreated_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tPRIMARY KEY (id), \n\tFOREIGN KEY(incident_id) REFERENCES incidents (id), \n\tFOREIGN KEY(author_id) REFERENCES users (id)\n)"
    )

    op.execute("CREATE INDEX ix_comments_incident_id ON comments (incident_id)")

    op.execute(
        "CREATE TABLE idempotency_records (\n\tuser_id UUID NOT NULL, \n\tkey VARCHAR(100) NOT NULL, \n\trequest_hash VARCHAR(64) NOT NULL, \n\tincident_id UUID NOT NULL, \n\tid UUID NOT NULL, \n\tcreated_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tPRIMARY KEY (id), \n\tUNIQUE (user_id, key), \n\tFOREIGN KEY(user_id) REFERENCES users (id), \n\tFOREIGN KEY(incident_id) REFERENCES incidents (id)\n)"
    )

    op.execute(
        "CREATE TABLE incident_assignments (\n\tincident_id UUID NOT NULL, \n\torganization_id UUID NOT NULL, \n\tassigned_by UUID NOT NULL, \n\texecutor_name VARCHAR(100), \n\tassigned_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tdue_at TIMESTAMP WITH TIME ZONE, \n\tcompleted_at TIMESTAMP WITH TIME ZONE, \n\tid UUID NOT NULL, \n\tcreated_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tPRIMARY KEY (id), \n\tUNIQUE (incident_id), \n\tFOREIGN KEY(incident_id) REFERENCES incidents (id), \n\tFOREIGN KEY(organization_id) REFERENCES organizations (id), \n\tFOREIGN KEY(assigned_by) REFERENCES users (id)\n)"
    )

    op.execute(
        "CREATE TABLE incident_confirmations (\n\tincident_id UUID NOT NULL, \n\tuser_id UUID NOT NULL, \n\tstatus VARCHAR(30) NOT NULL, \n\tcomment VARCHAR(1000), \n\tid UUID NOT NULL, \n\tcreated_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tPRIMARY KEY (id), \n\tUNIQUE (incident_id, user_id, status), \n\tFOREIGN KEY(incident_id) REFERENCES incidents (id), \n\tFOREIGN KEY(user_id) REFERENCES users (id)\n)"
    )

    op.execute(
        "CREATE INDEX ix_incident_confirmations_incident_id ON incident_confirmations (incident_id)"
    )

    op.execute("CREATE INDEX ix_incident_confirmations_user_id ON incident_confirmations (user_id)")

    op.execute(
        "CREATE TABLE incident_duplicates (\n\tsource_incident_id UUID NOT NULL, \n\ttarget_incident_id UUID NOT NULL, \n\tsimilarity_score FLOAT NOT NULL, \n\tdistance_meters FLOAT NOT NULL, \n\ttext_similarity FLOAT NOT NULL, \n\timage_similarity FLOAT, \n\tstatus VARCHAR(20) NOT NULL, \n\tid UUID NOT NULL, \n\tcreated_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tPRIMARY KEY (id), \n\tUNIQUE (source_incident_id, target_incident_id), \n\tFOREIGN KEY(source_incident_id) REFERENCES incidents (id), \n\tFOREIGN KEY(target_incident_id) REFERENCES incidents (id)\n)"
    )

    op.execute(
        "CREATE TABLE incident_media (\n\tincident_id UUID NOT NULL, \n\tupload_id UUID NOT NULL, \n\tmedia_type VARCHAR(10) NOT NULL, \n\toriginal_url VARCHAR(300) NOT NULL, \n\tredacted_url VARCHAR(300) NOT NULL, \n\tthumbnail_url VARCHAR(300) NOT NULL, \n\tid UUID NOT NULL, \n\tcreated_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tPRIMARY KEY (id), \n\tFOREIGN KEY(incident_id) REFERENCES incidents (id), \n\tUNIQUE (upload_id), \n\tFOREIGN KEY(upload_id) REFERENCES uploads (id)\n)"
    )

    op.execute("CREATE INDEX ix_incident_media_incident_id ON incident_media (incident_id)")

    op.execute(
        "CREATE TABLE timeline_events (\n\tincident_id UUID NOT NULL, \n\tstatus VARCHAR(40) NOT NULL, \n\tnote VARCHAR(1000) NOT NULL, \n\tid UUID NOT NULL, \n\tcreated_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tPRIMARY KEY (id), \n\tFOREIGN KEY(incident_id) REFERENCES incidents (id)\n)"
    )

    op.execute("CREATE INDEX ix_timeline_events_incident_id ON timeline_events (incident_id)")

    op.execute(
        "CREATE TABLE content_reports (\n\treporter_id UUID NOT NULL, \n\tincident_id UUID, \n\tcomment_id UUID, \n\treason VARCHAR(1000) NOT NULL, \n\tstatus VARCHAR(30) NOT NULL, \n\tid UUID NOT NULL, \n\tcreated_at TIMESTAMP WITH TIME ZONE NOT NULL, \n\tPRIMARY KEY (id), \n\tCHECK ((incident_id IS NULL) != (comment_id IS NULL)), \n\tFOREIGN KEY(reporter_id) REFERENCES users (id), \n\tFOREIGN KEY(incident_id) REFERENCES incidents (id), \n\tFOREIGN KEY(comment_id) REFERENCES comments (id)\n)"
    )

    op.execute("CREATE INDEX ix_incidents_location_gist ON incidents USING GIST (location)")


def downgrade() -> None:
    op.drop_table("content_reports")
    op.drop_table("timeline_events")
    op.drop_table("incident_media")
    op.drop_table("incident_duplicates")
    op.drop_table("incident_confirmations")
    op.drop_table("incident_assignments")
    op.drop_table("idempotency_records")
    op.drop_table("comments")
    op.drop_table("uploads")
    op.drop_table("refresh_sessions")
    op.drop_table("incidents")
    op.drop_table("audit_logs")
    op.drop_table("users")
    op.drop_table("organizations")
    op.drop_table("categories")
